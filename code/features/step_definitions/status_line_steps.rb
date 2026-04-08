require_relative '../../lib/cuke/status_line'
require_relative '../../lib/cuke/dude'
require_relative '../../lib/dude/status_line/format'

World(Cuke::Dude)
World(Cuke::StatusLine)

Before { Cuke::StatusLine.world = self }

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
  @context_percent = 0
end

Given('the {word} model') do |model|
  @active_model = model
end

Given(/^(\d+) haiku at \$(\d+), (\d+) sonnet at \$(\d+), (\d+) opus at (\d+)\$ requests$/) do |*counts|
  set_activity_response(build_models_from_counts(counts))
end

Then(/^the "(.*?)" section shows "(.*?)"(?: in (\w+))?$/) do |section_name, expected, color|
  Cuke::StatusLine.verify(section_name, expected, color)
end

Then(/^the "(.*?)" section is empty$/) do |section_name|
  output = dude('status_line').strip
  section = Cuke::StatusLineResult.new(output)[section_name]
  raise "Expected empty section, got '#{section.cleaned}'" unless section.cleaned.strip.empty?
end
