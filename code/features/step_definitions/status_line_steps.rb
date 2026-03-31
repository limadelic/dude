require_relative '../../lib/dude/status_line/format'

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

def status_json
  json = { context_window: { used_percentage: @context_percent } }
  json[:model] = { id: @active_model } if @active_model
  json.to_json
end

Given('the {word} model') do |model|
  @active_model = model
end

Given(/^(\d+) haiku at \$(\d+), (\d+) sonnet at \$(\d+), (\d+) opus at (\d+)\$ requests$/) do |*counts|
  set_activity_response(build_models_from_counts(counts))
end

def build_models_from_counts(counts)
  h, hc, s, sc, o, oc = counts
  { haiku: { count: h.to_i, cost: hc.to_i }, sonnet: { count: s.to_i, cost: sc.to_i }, opus: { count: o.to_i, cost: oc.to_i } }
end

def set_activity_response(models)
  breakdown, total_spend = build_models_breakdown(models)
  Cuke::ActivityServer.set_response(activity_response_payload(total_spend, breakdown))
end

def build_models_breakdown(models)
  breakdown, total = {}, 0
  models.each { |m, d| spend = d[:count] * d[:cost]; total += spend; breakdown[m.to_s] = { 'metrics' => { 'successful_requests' => d[:count], 'spend' => spend } } }
  [breakdown, total]
end

def activity_response_payload(total_spend, breakdown)
  { 'results' => [{ 'metrics' => { 'spend' => total_spend }, 'breakdown' => { 'models' => breakdown } }] }
end

Then(/^the "(Context|Spend|Models)" (bar|section) shows "(.*?)"(?: in (\w+))?$/) do |section_name, _type, expected, color|
  output = dude('status_line', stdin: status_json).strip
  expected_color = color ? Dude::StatusLine::Format::COLORS[color.to_sym] : nil
  cleaned = Dude::StatusLine::Format.strip(output)
  send("check_#{section_name.downcase}", cleaned, output, expected, expected_color, color)
end

Then(/^the "(Dudes)" (bar|section) shows "(.*?)"$/) do |_section, _type, expected|
  normalize = ->(s) { s.gsub(/\s+/, '') }
  wait_for("Dudes to show '#{expected}'") do
    output = dude('status_line').strip
    cleaned = Dude::StatusLine::Format.strip(output)
    normalize[cleaned].include?(normalize[expected])
  end
end

Then(/^the "(.*?)" section is empty$/) do |_section|
  output = dude('status_line', stdin: status_json).strip
  cleaned = Dude::StatusLine::Format.strip(output)
  raise "Expected empty section, got '#{cleaned}'" unless cleaned.scan(/[ˣ⁰¹²³⁴⁵⁶⁷⁸⁹]/).empty?
end

def check_models(cleaned, output, expected, expected_color, color)
  verify_models_section(cleaned, expected) && verify_models_formatting(output, expected, expected_color, color)
end

def verify_models_section(cleaned, expected)
  expected_normalized = expected.gsub(' ', '').delete('[]')
  actual_models = extract_models_section(cleaned)
  raise "Expected Models '#{expected_normalized}' in cleaned output, got: #{actual_models}" unless actual_models == expected_normalized
end

def verify_models_formatting(output, expected, expected_color, color)
  expected.include?('[') ? verify_bracketed_models(output, expected, expected_color, color) : verify_simple_color(output, color, expected_color)
end

def verify_bracketed_models(output, expected, expected_color, color)
  match = expected.match(/\[([🐸🎭🎸][⁰¹²³⁴⁵⁶⁷⁸⁹]*)\]/)
  check_model_background(output, match[1][0], expected_color, color) if match
end

def verify_simple_color(output, color, expected_color)
  raise "Expected color #{color} in output" unless output.include?(expected_color)
end

def check_context(cleaned, output, expected, expected_color, color)
  raise "Expected bar '#{expected}' in output, got: #{cleaned}" unless cleaned.include?(expected)
  raise "Expected color #{color} in output" unless output.include?(expected_color)
end

def check_spend(cleaned, output, expected, expected_color, color)
  raise "Expected bar '#{expected}' in output, got: #{cleaned}" unless cleaned.include?(expected)
  raise "Expected color #{color} in output" unless output.include?(expected_color)
end

def extract_models_section(cleaned)
  models_part = cleaned.split('🎳').first.to_s
  models_part.gsub!(/🧠[░█]+/, '')
  models_part.gsub!(/💰[░█]+/, '')
  models_part.gsub!(/\s+/, '')
  models_part.scan(/[🐸🎭🎸][⁰¹²³⁴⁵⁶⁷⁸⁹]*/).join
end

def check_model_background(output, model_emoji, expected_color, color_name)
  bg_color = Dude::StatusLine::Format::BG_MAP[expected_color] || expected_color
  raise "Expected #{color_name} background for #{model_emoji}" unless output.include?(bg_color)
end
