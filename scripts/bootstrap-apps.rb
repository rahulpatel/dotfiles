#!/usr/bin/env ruby
# Run after dotfiles deployment. Never copy entire preference domains or app data.
require 'json'
require 'open3'
require 'fileutils'
require 'time'

class BootstrapApps
  ROOT = File.expand_path('..', __dir__)

  CAPTURE_APPS = ['macshot.app', 'Tailscale.app'].freeze

  def initialize(home: Dir.home, dry_run: false, settings_path: File.join(ROOT, 'settings/apps.json'))
    @home = home
    @dry_run = dry_run
    @settings_path = settings_path
  end

  def command(*args, **options)
    stdout, stderr, status = Open3.capture3(*args, **options)
    raise "#{args.first}: #{stderr.strip}" unless status.success?
    stdout
  end

  def installed_path(name)
    [File.join('/Applications', name), File.join(@home, 'Applications', name)].find { |p| File.directory?(p) }
  end

  # defaults accepts XML values, preserving booleans, integers and array element types.
  def plist(value)
    case value
    when true then '<true/>'
    when false then '<false/>'
    when Integer then "<integer>#{value}</integer>"
    when String
      escaped = value.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
      "<string>#{escaped}</string>"
    when Array then "<array>#{value.map { |item| plist(item) }.join}</array>"
    else raise "Unsupported preference type: #{value.class}"
    end
  end

  def read_preferences(domain, keys)
    if domain.start_with?('/')
      # Sandboxed apps use an explicit plist path; defaults may silently ignore these writes.
      path = "#{domain}.plist"
      return {} unless File.exist?(path)
      stdout = File.binread(path)
    else
      stdout, stderr, status = Open3.capture3('/usr/bin/defaults', 'export', domain, '-')
      unless status.success?
        return {} if stderr.include?('does not exist') || stderr.include?('could not be found')
        raise "Cannot read #{domain}: #{stderr.strip}"
      end
    end
    keys.to_h do |key|
      xml, error, result = Open3.capture3('/usr/bin/plutil', '-extract', key, 'xml1', '-o', '-', '-', stdin_data: stdout)
      unless result.success?
        raise "Cannot extract #{key}: #{xml}#{error}" unless (xml + error).include?('No value at that key path')
        xml = nil
      end
      [key, xml]
    end
  end

  def backup(domain, current, keys)
    # Save managed values as typed XML; null means the key was absent. No vault/profile data.
    @backup_dir ||= begin
      dir = File.join(@home, '.local/state/dotfiles/app-preferences', Time.now.utc.iso8601(6).tr(':', '-'))
      FileUtils.mkdir_p(dir, mode: 0o700)
      dir
    end
    path = File.join(@backup_dir, "#{File.basename(domain)}.json")
    File.write(path, JSON.pretty_generate({ 'domain' => domain, 'settings' => keys.to_h { |key| [key, current[key]] } }) + "\n", perm: 0o600)
    puts "  Backup: #{path}"
  end

  def restore(app)
    settings = app.fetch('settings', {})
    return if settings.empty?
    if app['name'] == 'Tinycast.app'
      path = File.join(@home, '.config/tinycast/settings.json')
      raise "Tinycast settings missing: #{path}; deploy dotfiles first" unless File.file?(path)
      JSON.parse(File.read(path))
    end
    domain = app.fetch('domain').gsub('~', @home)
    current = read_preferences(domain, settings.keys)
    desired = settings.transform_values do |value|
      command('/usr/bin/plutil', '-convert', 'xml1', '-o', '-', '-',
              stdin_data: "<plist version=\"1.0\">#{plist(value)}</plist>")
    end
    changes = settings.keys.select { |key| current[key] != desired[key] }
    return if changes.empty?
    puts "  #{@dry_run ? 'Would apply' : 'Applying'} #{changes.join(', ')}"
    return if @dry_run
    backup(domain, current, changes)
    if domain.start_with?('/')
      path = "#{domain}.plist"
      FileUtils.mkdir_p(File.dirname(path))
      command('/usr/bin/plutil', '-create', 'xml1', path) unless File.exist?(path)
      changes.each { |key| command('/usr/bin/plutil', '-replace', key, '-xml', plist(settings.fetch(key)), path) }
    else
      changes.each { |key| command('/usr/bin/defaults', 'write', domain, key, plist(settings.fetch(key))) }
    end
    actual = read_preferences(domain, changes)
    raise 'Preference writes did not persist' unless changes.all? { |key| actual[key] == desired[key] }
    # Never quit apps: a running app can cache or overwrite externally changed preferences.
    puts '  If already running, quit and reopen this app to load changed preferences.'
  end

  def capture
    apps = JSON.parse(File.read(@settings_path))
    changed = false
    apps.each do |app|
      next unless CAPTURE_APPS.include?(app.fetch('name'))
      unless installed_path(app['name'])
        puts "Skipping #{app['name']} (not installed)"
        next
      end
      settings = app.fetch('settings')
      current = read_preferences(app.fetch('domain').gsub('~', @home), settings.keys)
      settings.keys.each do |key|
        xml = current[key]
        unless xml
          warn "Skipping #{app['name']}: #{key} is unset; keeping the saved value"
          next
        end
        # Wrap the scalar in a dictionary: plutil cannot export a root boolean as JSON.
        body = xml.match(/<plist[^>]*>(.*)<\/plist>/m)&.captures&.first
        raise "Invalid plist for #{key}" unless body
        wrapped = "<plist version=\"1.0\"><dict><key>value</key>#{body}</dict></plist>"
        value = JSON.parse(command('/usr/bin/plutil', '-convert', 'json', '-o', '-', '-', stdin_data: wrapped)).fetch('value')
        plist(value) # Reject unsupported types before updating the snapshot.
        raise "Unexpected type for #{app['name']}: #{key}" unless value.class == settings[key].class || [true, false].include?(value) && [true, false].include?(settings[key])
        next if value == settings[key]
        puts "#{@dry_run ? 'Would capture' : 'Capturing'} #{app['name']}: #{key}"
        settings[key] = value
        changed = true
      end
    end
    if changed && !@dry_run
      # Write only after every app has been read successfully; atomically replace the snapshot.
      temp = "#{@settings_path}.tmp-#{Process.pid}"
      begin
        File.write(temp, JSON.pretty_generate(apps) + "\n", perm: 0o600)
        File.chmod(File.stat(@settings_path).mode & 0o777, temp)
        File.rename(temp, @settings_path)
      ensure
        FileUtils.rm_f(temp)
      end
    end
    puts 'Snapshot already matches available preferences.' unless changed
    puts 'Tinycast syncs its JSON directly; edit AeroSpace config directly. 1Password remains manual.'
  end

  def run
    apps = JSON.parse(File.read(@settings_path))
    apps.each do |app|
      unless installed_path(app.fetch('name'))
        puts "Skipping #{app['name']} (not installed)"
        next
      end
      puts app['name']
      begin
        restore(app)
      rescue StandardError => e
        # Report a failed restore, but continue with the other apps.
        warn "  Warning: #{app['name']}: #{e.message}"
      end
    end
    puts 'Manual app setup: grant Accessibility / Screen Recording as requested; sign in to 1Password and Tailscale.'
  end
end

if $PROGRAM_NAME == __FILE__
  action = ARGV.first == '--dry-run' || ARGV.empty? ? 'apply' : ARGV.shift
  abort 'Usage: ruby scripts/bootstrap-apps.rb [apply|capture] [--dry-run]' unless ['apply', 'capture'].include?(action) && (ARGV - ['--dry-run']).empty?
  abort 'This script requires macOS' unless RUBY_PLATFORM.include?('darwin')
  runner = BootstrapApps.new(dry_run: ARGV.include?('--dry-run'))
  action == 'capture' ? runner.capture : runner.run
end
