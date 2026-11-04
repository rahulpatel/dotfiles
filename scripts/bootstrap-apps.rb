#!/usr/bin/env ruby
# Run after dotfiles deployment. Never copy entire preference domains or app data.
require 'json'
require 'open3'
require 'fileutils'
require 'time'

class BootstrapApps
  ROOT = File.expand_path('..', __dir__)

  def initialize(home: Dir.home, dry_run: false)
    @home = home
    @dry_run = dry_run
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

  def run
    apps = JSON.parse(File.read(File.join(ROOT, 'settings/apps.json')))
    apps.each do |app|
      path = installed_path(app.fetch('name'))
      unless path
        puts "Skipping #{app['name']} (not installed)"
        next
      end
      puts app['name']
      begin
        restore(app)
        if @dry_run
          puts "  Would launch #{path} in background"
        else
          command('/usr/bin/open', '-g', path)
        end
      rescue StandardError => e
        # Do not launch with a failed restore, but continue with the other apps.
        warn "  Warning: #{app['name']}: #{e.message}"
      end
    end
    puts 'Manual app setup: grant Accessibility / Screen Recording as requested; sign in to 1Password and Tailscale.'
  end
end

if $PROGRAM_NAME == __FILE__
  abort 'Usage: ruby scripts/bootstrap-apps.rb [--dry-run]' unless (ARGV - ['--dry-run']).empty?
  abort 'This script requires macOS' unless RUBY_PLATFORM.include?('darwin')
  BootstrapApps.new(dry_run: ARGV.include?('--dry-run')).run
end
