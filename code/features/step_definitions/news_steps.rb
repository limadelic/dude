require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/news'
require_relative '../../lib/cuke/activity_server'

World(Cuke::Dude)
World(Cuke::News)

Before('@wip') do
  Cuke::ActivityServer.start
  @home = Dir.home
end

After('@wip') do
  ENV.delete('DUDE_NEWS_MOCK')
  ENV.delete('CC_VERSION')
end

Given('CC is installed at {string}') do |version|
  setup_installed_version(version)
end

Given('latest CC release is {string}') do |version|
  setup_latest_version(version)
end

Given('GHA workflow conclusion is {string}') do |conclusion|
  setup_workflow_conclusion(conclusion)
end

Then('shows {string}') do |text|
  raise "Expected '#{text}' in output" unless @output&.include?(text)
end

Then('shows') do |table|
  table.raw.flatten.each do |text|
    raise "Expected '#{text}' in output" unless @output&.include?(text)
  end
end

When(/^> \/news\s*(.*)$/) do |args|
  ENV['DUDE_NEWS_MOCK'] = 'true'
  ENV['DUDE_NEWS_MOCK_DATA'] = '/tmp/dude_news_mock_data.json'
  output_file = "/tmp/dude_news_#{Time.now.to_i}.txt"
  version = ENV['CC_VERSION']
  cmd = "CC_VERSION=#{version} DUDE_NEWS_MOCK=true "
  cmd += "DUDE_NEWS_MOCK_DATA=/tmp/dude_news_mock_data.json dude news #{args}"
  system("#{cmd} > #{output_file} 2>&1")
  @output = File.read(output_file)
  File.delete(output_file) rescue nil
end
