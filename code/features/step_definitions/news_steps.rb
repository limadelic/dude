require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/news'
require 'rspec/mocks/standalone'

World(Cuke::Dude)
World(Cuke::News)

Before('@news') do
  @home = Dir.home
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
  source = RSpec::Mocks::Double.new(
    'GithubSource',
    latest_version: @latest_version,
    workflow_conclusion: @workflow_conclusion,
    run_url: 'https://github.com/UKGEPIC/dude/actions/runs/12345',
    releases: mock_releases_for(10)
  )
  @output = capture_output do
    Dude::News::News.new(limit: limit, source: source).run
  end
end

When(/^> \/news --limit (\d+)$/) do |limit_str|
  limit = limit_str.to_i
  source = RSpec::Mocks::Double.new(
    'GithubSource',
    latest_version: @latest_version,
    workflow_conclusion: @workflow_conclusion,
    run_url: 'https://github.com/UKGEPIC/dude/actions/runs/12345',
    releases: mock_releases_for(10)
  )
  @output = capture_output do
    Dude::News::News.new(limit: limit, source: source).run
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
