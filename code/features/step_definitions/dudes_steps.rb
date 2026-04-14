require 'tmpdir'
require 'fileutils'
require 'rspec/mocks/standalone'
require_relative '../../lib/cuke/dude'
require_relative '../../lib/dude/helpers/gh'
require_relative '../../lib/dude/news/news'
require_relative '../../lib/dude/news/paperboy'
require_relative '../../lib/dude/news/sommelier'

World(Cuke::Dude)
World(RSpec::Mocks::ExampleMethods)

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

Before('@news') do
  @mocks = {
    'claude --version' => '2.1.90',
    'gh release list -R anthropics/claude-code --limit 1' => 'v2.1.96',
    'gh run list --repo UKGEPIC/dude --json status' => 'completed',
    'gh run list --repo UKGEPIC/dude --json conclusion' => 'success',
    'gh release list -R anthropics/claude-code' => %w[
      v2.1.96 v2.1.95 v2.1.94 v2.1.93 v2.1.92
    ].join("\n")
  }
end

After('@news') do
  ENV.delete('CC_VERSION')
end

When(/^! (.+)$/) do |cmd, *rest|
  table = rest.flatten.compact.first
  @mocks ||= {}
  if table
    values = table.raw.flatten.map(&:strip)
    @mocks[cmd] = values.size == 1 ? values.first : values.join("\n")
  end
end

When(/^> \/(.+):$/) do |command, table|
  if @mocks
    run_with_mocks(command)
  else
    run(@home, command)
  end

  verify_table(table)
end

def run_with_mocks(command)
  @mocks ||= {}
  @mocks.each do |cmd, val|
    ENV['CC_VERSION'] = val if cmd.include?('claude --version')
  end

  mocks = @mocks
  gh = instance_double(Dude::Helpers::Gh)
  allow(gh).to receive(:run) do |run_cmd|
    match = mocks.find do |pattern, _|
      key = pattern.sub(/^gh\s+/, '')
      key.split.all? { |word| run_cmd.include?(word) }
    end
    match ? match[1] : ''
  end

  limit_match = command.match(/--limit\s+(\d+)/)
  limit = limit_match ? limit_match[1].to_i : 5

  paperboy = Dude::News::Paperboy.new(gh: gh)
  sommelier = Dude::News::Sommelier.new(gh: gh)

  news = Dude::News::News.new(
    limit: limit,
    paperboy: paperboy,
    sommelier: sommelier
  )
  @output = capture_stdout { news.run }
end

private

def capture_stdout
  original = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string.chomp
ensure
  $stdout = original
end

def verify_table(table)
  table.raw.flatten.each do |row|
    row = row.strip
    if row.start_with?('(') && row.end_with?(')')
      verify_negative(row[1..-2])
    else
      verify_positive(row)
    end
  end
end

def verify_positive(expected)
  if @mocks
    raise "Expected '#{expected}' in output:\n#{@output}" unless @output.include?(expected)
  else
    wait_for("shows #{expected}") do
      output = dude('status_line').strip
      expected.split.all? { |part| output.include?(part) }
    end
  end
end

def verify_negative(val)
  if @mocks
    raise "Not expected '#{val}' in output:\n#{@output}" if @output.include?(val)
  else
    output = dude('status_line').strip
    raise "Not expected '#{val}' in status line:\n#{output}" if output.include?(val)
  end
end

def capture_output
  out = $stdout = StringIO.new
  yield
  out.string
ensure
  $stdout = STDOUT
end
