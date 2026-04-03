require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/status_line'
require_relative '../../lib/dude/status_line/format'

World(Cuke::Dude)
World(Cuke::StatusLine)

Before { Cuke::StatusLine.world = self }

Given('dude is running') do
  @context_percent = nil
  @prompt_bar_color = nil
end

Given('the prompt bar is {word}') do |color|
  @prompt_bar_color = color.to_sym
  @context_percent = case color
                     when 'green'
                       20
                     when 'yellow'
                       50
                     when 'red'
                       85
                     else
                       raise "Unknown color: #{color}"
                     end
end

Given('context usage is {int}%') do |percent|
  @context_percent = percent
  @activity = nil
end

When('context usage rises to {int}%') do |percent|
  @context_percent = percent
end

Then('the prompt bar turns {word}') do |color|
  expected_color = color
  output = dude('status_line', stdin: status_json).strip

  color_sym = expected_color.to_sym
  fg_code = ::Dude::StatusLine::Format::COLORS[color_sym]
  bg_code = ::Dude::StatusLine::Format::COLORS[:"bg_#{expected_color}"]

  has_color = output.include?(fg_code) || output.include?(bg_code)
  raise "Expected prompt bar to be #{expected_color}, got: #{output}" unless has_color
end
