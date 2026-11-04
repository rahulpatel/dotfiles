#!/usr/bin/env ruby
# Uses temporary preference files only; never launches apps or changes real app domains.
require 'tmpdir'
require_relative '../scripts/bootstrap-apps'

def assert(condition, message)
  raise message unless condition
end

abort 'Tests require macOS plutil/defaults' unless RUBY_PLATFORM.include?('darwin')

Dir.mktmpdir('dotfiles-apps-test') do |home|
  runner = BootstrapApps.new(home: home)
  domain = File.join(home, 'sandbox/Data/Library/Preferences/preferences')
  settings = { 'flag' => true, 'disabled' => false, 'number' => 12, 'text' => 'A < B & C', 'list' => [1, 2, 15] }
  app = { 'name' => 'Test.app', 'domain' => domain, 'settings' => settings }
  assert(runner.read_preferences(domain, settings.keys).values.all?(&:nil?), 'Fresh domain should have no keys')
  # The absolute sandbox preferences directory does not exist on a fresh install.
  runner.restore(app)
  assert(File.file?("#{domain}.plist"), 'Fresh sandbox settings were not persisted')
  runner.command('/usr/bin/plutil', '-replace', 'unmanaged', '-string', 'keep me', "#{domain}.plist")
  runner.command('/usr/bin/plutil', '-replace', 'binary', '-data', 'AP8=', "#{domain}.plist")

  # Scalars, arrays and escaped strings round-trip with their exact types.
  runner.restore(app)
  values = runner.read_preferences(domain, settings.keys)
  settings.each do |key, value|
    expected = runner.command('/usr/bin/plutil', '-convert', 'xml1', '-o', '-', '-',
                              stdin_data: "<plist version=\"1.0\">#{runner.plist(value)}</plist>")
    assert(values[key] == expected, "Wrong type/value for #{key}")
  end
  assert(runner.command('/usr/bin/plutil', '-extract', 'unmanaged', 'raw', '-o', '-', "#{domain}.plist").strip == 'keep me', 'Unmanaged key changed')
  backups = Dir.glob(File.join(home, '.local/state/dotfiles/app-preferences/*/*.json'))
  assert(backups.length == 1, 'Expected one backup')
  backup = JSON.parse(File.read(backups.first))
  assert(backup.fetch('settings') == settings.keys.to_h { |k| [k, nil] }, 'Backup should contain only managed keys')
  assert(File.stat(backups.first).mode & 0o777 == 0o600, 'Backup permissions must be private')

  # Already-matching settings must not be written/backed up again.
  bytes = File.binread("#{domain}.plist")
  runner.restore(app)
  assert(File.binread("#{domain}.plist") == bytes, 'Repeat restore wrote preferences')

  changed = app.merge('settings' => { 'flag' => false })
  BootstrapApps.new(home: home, dry_run: true).restore(changed)
  assert(File.binread("#{domain}.plist") == bytes, 'Dry-run wrote preferences')
  runner.restore(changed)
  saved = JSON.parse(File.read(backups.first)).fetch('settings').fetch('flag')
  assert(saved.include?('<true/>'), 'Backup must preserve the previous typed value')

  # Tinycast must never be enabled before a valid settings file is deployed.
  tinycast = { 'name' => 'Tinycast.app', 'domain' => domain, 'settings' => { 'settingsFileEnabled' => true } }
  begin
    runner.restore(tinycast)
    raise 'Missing Tinycast file was accepted'
  rescue RuntimeError => e
    raise unless e.message.include?('Tinycast settings missing')
  end
  FileUtils.mkdir_p(File.join(home, '.config/tinycast'))
  File.write(File.join(home, '.config/tinycast/settings.json'), '{}')
  runner.restore(tinycast)
  assert(runner.read_preferences(domain, ['settingsFileEnabled']).fetch('settingsFileEnabled').include?('<true/>'), 'Tinycast mirror not enabled')
end

class LaunchProbe < BootstrapApps
  attr_reader :events
  def initialize
    @events = []
  end
  def installed_path(name)
    return nil if name == 'Tailscale.app'
    "/Applications/#{name}"
  end
  def restore(app)
    @events << [:restore, app['name']]
    raise 'simulated restore failure' if app['name'] == 'macshot.app'
  end
  def command(*args, **_options)
    @events << [:command, *args]
  end
end
probe = LaunchProbe.new
probe.run
launches = probe.events.select { |e| e.first == :command }
assert(launches.length == 3, 'Missing app/failed restore should not launch')
assert(launches.all? { |e| e[1] == '/usr/bin/open' && e[2] == '-g' }, 'Launches must use open -g')
launches.each do |event|
  name = File.basename(event.last)
  assert(probe.events.index([:restore, name]) < probe.events.index(event), 'App launched before restore')
end
puts 'App bootstrap tests passed'
