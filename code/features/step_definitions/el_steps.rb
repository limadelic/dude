# frozen_string_literal: true

# rubocop:disable Naming/FileName
require_relative "../../lib/cuke/el"

World(Cuke::El)

Before do
  spawn_claude
end

After do
  cleanup_claude
end

Given("a Claude process in stream-json mode") do
  # Already spawned in Before hook
end

When("I send {string}") do |message|
  send_message(message)
  @last_response = read_response
end

Then("I get a successful response") do
  expect(@last_response).not_to be_nil
end

Then("I get a successful response containing {string}") do |text|
  expect(@last_response).to include(text)
end
