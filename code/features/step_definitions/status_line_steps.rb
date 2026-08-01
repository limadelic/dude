require 'json'
require_relative '../../lib/cuke/status_line'
require_relative '../../lib/cuke/dude'
require_relative '../../lib/dude/status_line/format'
require_relative '../../lib/dude/status_line/anthropic_token'
require_relative '../../lib/dude/status_line/daily_checkpoint'
require_relative '../support/status_line_helpers'

World(Cuke::Dude)
World(Cuke::StatusLine)
World(StatusLineHelpers)

Before do
  Cuke::StatusLine.world = self
  reset_checkpoint_file
end

def reset_checkpoint_file
  checkpoint_path = File.expand_path('~/.claude/status.json')
  File.delete(checkpoint_path) if File.exist?(checkpoint_path)
end

MODELS_PATTERN = %r{^(\d+) haiku at \$(\d+), (\d+) sonnet at \$(\d+), \
                     (\d+) opus at (\d+)\$ requests$}

Given('{int}% context usage') do |percent|
  @context_percent = percent
  @activity = nil
end

Given('daily allowance is ${int}') do |cap|
  ENV['CLAUDE_SPEND_CAP'] = cap.to_s
end

Given('${int} spent') do |spend|
  Cuke::ActivityServer.set_response(
    { 'results' => [{ 'metrics' => { 'spend' => spend } }] }
  )
  stub_anthropic_token
  reset_checkpoint
  stub_deterministic_time
  @context_percent = 0
end

def stub_anthropic_token
  allow(Dude::StatusLine::AnthropicToken)
    .to receive(:fetch).and_return('test_token')
  creds_path = '/tmp/dude-test-credentials.json'
  creds = { claudeAiOauth: { accessToken: 'test_token' } }
  File.write(creds_path, creds.to_json)
end

def reset_checkpoint
  checkpoint_path = File.expand_path('~/.claude/status.json')
  File.delete(checkpoint_path) if File.exist?(checkpoint_path)
end

def stub_deterministic_time
  ENV['CLAUDE_TEST_TIME'] = '2026-06-15T14:00:00'
end

Given('the {word} model') do |model|
  @active_model = model
end

Given(MODELS_PATTERN) do |*counts|
  set_activity_response(build_models_from_counts(counts))
end

Then(
  /^the "(.*?)" section shows "(.*?)"(?: in (\w+))?$/
) do |section_name, expected, color|
  Cuke::StatusLine.verify(section_name, expected, color)
end

Then(/^the "(.*?)" section is empty$/) do |section_name|
  output = dude('status_line').strip
  section = Cuke::StatusLineResult.new(output)[section_name]
  verify_status_section_empty(section_name, section)
end
