require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/status_line'
require_relative '../../lib/dude/status_line/format'

World(Cuke::Dude)
World(Cuke::StatusLine)

Before { Cuke::StatusLine.world = self }

When('context changes to {int}%') do |percent|
  @context_percent = percent
end

When('dude starts') do
  # Trigger startup — context_percent already set via Given
end

Then('prompt bar is {word}') do |color|
  output = dude('status_line', stdin: status_json).strip

  color_sym = color.to_sym
  fg_code = ::Dude::StatusLine::Format::COLORS[color_sym]
  bg_code = ::Dude::StatusLine::Format::COLORS[:"bg_#{color}"]

  has_color = output.include?(fg_code) || output.include?(bg_code)
  raise "Expected prompt bar to be #{color}, got: #{output}" unless has_color
end
