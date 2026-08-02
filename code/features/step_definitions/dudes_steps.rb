require 'tmpdir'
require 'fileutils'
require 'rspec/mocks/standalone'
require_relative '../../lib/cuke/dude'
require_relative '../support/dudes_helpers'

World(Cuke::Dude)
World(RSpec::Mocks::ExampleMethods)
World(DudesHelpers)

Before('@dudes') do
  @temp_dir = Dir.mktmpdir('dude_test_')
  @dude_home = File.join(@temp_dir, '.claude', 'dudes')
  FileUtils.mkdir_p(@dude_home)
  ENV['DUDE_HOME'] = @dude_home
  ENV['DUDE_PROCESS'] = 'dude_test'
end

After do
  RSpec::Mocks.teardown if @mocks
  RSpec::Mocks.setup if @mocks
  @mocks = nil
end

After('@dudes') do
  cleanup
  `pkill -f dude_test 2>/dev/null`
  ENV.delete('DUDE_HOME')
  ENV.delete('DUDE_PROCESS')
  FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
end

Given(/^dudes$/) do |table|
  table.hashes.each { |row| setup_from_row(row) }
end

ICONS = { 'dude' => '🎳', 'elita' => '🐶' }

Given(/^dudes dude abides$/) do
  setup_from_row(
    'home' => 'dude', 'icon' => '🎳', 'pub' => 'yes',
    'abide' => 'yes'
  )
end

Given(/^dudes "([^"]+)" pub$/) do |names|
  names.split(/,\s*/).each do |name|
    setup_from_row(
      'home' => name, 'icon' => ICONS.fetch(name), 'pub' => 'yes',
      'abide' => 'no'
    )
  end
end

Given(/^dudes "([^"]+)" abide$/) do |names|
  names.split(/,\s*/).each do |name|
    setup_from_row(
      'home' => name, 'icon' => ICONS.fetch(name), 'pub' => 'yes',
      'abide' => 'yes'
    )
  end
end

When(/^@(\w+) > \/(.+):$/) do |name, command, table|
  case command
  when 'pub'
    setup_from_row(
      'home' => name, 'icon' => ICONS.fetch(name), 'pub' => 'yes',
      'abide' => 'no'
    )
  when 'abide'
    setup_from_row(
      'home' => name, 'icon' => ICONS.fetch(name), 'pub' => 'yes',
      'abide' => 'yes'
    )
  else
    @home = home(name)
    run(@home, command)
  end
  verify_table(table)
end

When(/^~ (.+)$/) do |cmd, *rest|
  table = rest.flatten.compact.first
  @mocks ||= []
  @mocks << [cmd, table&.raw&.flatten&.map(&:strip)&.join("\n")]
end

When(/^! ([^:]+)$/) do |cmd|
  system(cmd)
end

When(/^! ([^:]+):$/) do |cmd, table|
  output = `#{cmd}`.chomp
  table.raw.flatten.each do |expected|
    expected = expected.strip.gsub(/\$(\w+)/) { ENV[$1] || $& }
    verify_shell_output(cmd, expected, output)
  end
end

When(/^> \/(.+):$/) do |command, table|
  if @mocks
    stub_backticks(@mocks)
    require 'dude/helpers/cli'
    @output = capture_stdout { Dude::Helpers::Cli.start(command.split) }
  else
    run(@home, command)
  end

  verify_table(table)
end
