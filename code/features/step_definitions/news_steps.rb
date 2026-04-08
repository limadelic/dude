require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/news'
require_relative '../../lib/cuke/activity_server'

World(Cuke::Dude)
World(Cuke::News)

Before('@wip') do
  Cuke::ActivityServer.start
  @installed_version = nil
  @latest_version = nil
  @workflow_conclusion = nil
  @news_output = nil
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

# Use regex with non-greedy match for news-specific commands to take precedence
When(/^> \/news$/) do
  pending("kenny: implement dude news")
  run_dude_news('')
end

When(/^> \/news --limit (\d+)$/) do |limit|
  pending("kenny: implement dude news")
  run_dude_news("--limit #{limit}")
end

Then('output shows {string}') do |text|
  assert_output_contains(text)
end

Then('output shows {string} at the top') do |text|
  assert_output_starts_with(text)
end

Then('output shows the last {int} release notes') do |count|
  assert_releases_in_output(count)
end

Then('output shows only the last {int} release notes') do |count|
  assert_releases_in_output(count)
end

Then('output includes a link to the run logs') do
  assert_link_to_run_logs
end
