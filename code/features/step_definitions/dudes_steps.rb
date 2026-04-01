require 'tmpdir'
require 'fileutils'
require_relative '../../lib/cuke/dude'

World(Cuke::Dude)

Before('@dudes') do
  @temp_dir = Dir.mktmpdir('dude_test_')
  @dude_home = File.join(@temp_dir, '.claude', 'dudes')
  FileUtils.mkdir_p(@dude_home)
  ENV['DUDE_HOME'] = @dude_home
  ENV['DUDE_PROCESS'] = 'dude_test'
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
  setup_from_row('home' => 'dude', 'icon' => '🎳', 'pub' => 'yes', 'abide' => 'yes')
end

Given(/^dudes "([^"]+)" pub$/) do |names|
  names.split(/,\s*/).each do |name|
    setup_from_row('home' => name, 'icon' => ICONS.fetch(name), 'pub' => 'yes', 'abide' => 'no')
  end
end

Given(/^dudes "([^"]+)" abide$/) do |names|
  names.split(/,\s*/).each do |name|
    setup_from_row('home' => name, 'icon' => ICONS.fetch(name), 'pub' => 'yes', 'abide' => 'yes')
  end
end

When(/^(\w+) > \/(.+)$/) do |name, command|
  @home = home(name)
  run(@home, command)
end

When(/^> \/(.+)$/) do |command|
  run(@home, command)
end
