require_relative '../../lib/cuke/alley_pr'

World(Cuke::AlleyPr)

Given(/^current branch is (.+)$/) do |branch_name|
  set_current_branch(branch_name)
end

When(/^dude alley-pr is run$/) do
  run_alley_pr
end

Then(/^error message contains "(.+)"$/) do |expected_text|
  message = error_message
  raise "Expected '#{expected_text}' in error message, got: '#{message}'" unless message.include?(expected_text)
end
