require_relative '../../lib/dude/status_line/format'
require_relative '../../lib/cuke/pomo'

World(Cuke::Pomo)

Given(/^(\d+) passed into a (work|break|long break) session$/) do |minutes, session_type|
  config = {
    'work' => ['default', 1500],
    'break' => ['break', 300],
    'long break' => ['long break', 900]
  }
  label, total_secs = config[session_type]
  setup_pomo(label, total_secs, minutes.to_i)
end

Then('the "Pomo" bar shows {string} in {word}') do |bar, color_name|
  output = dude('pomo').strip
  expected_color = Dude::StatusLine::Format::COLORS[color_name.to_sym]
  cleaned = Dude::StatusLine::Format.strip(output)
  raise "Expected bar '#{bar}' in output, got: #{cleaned}" unless cleaned.include?(bar)
  raise "Expected color #{color_name} in output" unless output.include?(expected_color)
end

After do
  if defined?(@pomo_file) && @pomo_file
    File.unlink(@pomo_file.path) if File.exist?(@pomo_file.path)
  end
  ENV.delete('POMO_STATUS_FILE')
end
