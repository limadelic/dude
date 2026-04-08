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
  Cuke::ActivityServer.stop
  ENV.delete('DUDE_NEWS_MOCK')
  ENV.delete('CC_VERSION')
end

Given('I have Claude Code version {string} installed') do |version|
  setup_installed_version(version)
end

Given('the latest Claude Code version is {string}') do |version|
  setup_latest_version(version)
end

Given('the GHA workflow will complete with conclusion {string}') do |conclusion|
  setup_workflow_conclusion(conclusion)
end

When(/^I run dude news(?: --limit (\d+))?$/) do |limit|
  pending("kenny: implement dude news")
  args = limit ? "--limit #{limit}" : ''
  run_dude_news(args)
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

Then('output includes a link to the run logs') do
  assert_link_to_run_logs
end
