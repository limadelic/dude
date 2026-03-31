require 'tmpdir'
require 'fileutils'
require_relative '../../lib/cuke/dude_test_process'

World(Cuke::DudeTestProcess)

Before('@dudes') do
  @temp_dir = Dir.mktmpdir('dude_test_')
  @dude_home = File.join(@temp_dir, '.claude', 'dudes')
  FileUtils.mkdir_p(@dude_home)
  ENV['DUDE_HOME'] = @dude_home
  ENV['DUDE_PROCESS'] = 'dude_test'
end

After('@dudes') do
  cleanup
  ENV.delete('DUDE_HOME')
  ENV.delete('DUDE_PROCESS')
  FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
end

Given(/^dudes$/) do |table|
  table.hashes.each do |row|
    @home = resolve_home(row['home'])
    setup_dude(@home, row['icon'])
    dude('pub', row['home'], chdir: @home) if row['pub'] == 'yes'
  end
end

When(/^> \/(.+)$/) do |command|
  claude(@home, cmd: "dude #{command} & wait")
end
