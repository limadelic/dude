require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/news'
require 'rspec/mocks/standalone'

World(Cuke::Dude)
World(Cuke::News)

Before('@news') do
  @home = Dir.home
  @gh = build_gh
end

After('@news') do
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

When(/^> \/news$/) do
  limit = 5
  paperboy = Dude::News::Paperboy.new(gh: @gh)
  sommelier = Dude::News::Sommelier.new(gh: @gh)
  @output = capture_output do
    Dude::News::News.new(limit: limit, paperboy: paperboy, sommelier: sommelier).run
  end
end

When(/^> \/news --limit (\d+)$/) do |limit_str|
  limit = limit_str.to_i
  paperboy = Dude::News::Paperboy.new(gh: @gh)
  sommelier = Dude::News::Sommelier.new(gh: @gh)
  @output = capture_output do
    Dude::News::News.new(limit: limit, paperboy: paperboy, sommelier: sommelier).run
  end
end

Then('shows {string}') do |text|
  raise "Expected '#{text}' in output" unless @output&.include?(text)
end

Then('shows') do |table|
  table.raw.flatten.each do |text|
    raise "Expected '#{text}' in output" unless @output&.include?(text)
  end
end
