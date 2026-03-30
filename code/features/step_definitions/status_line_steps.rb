require_relative '../../lib/status_line/format'

Given('{int}% context usage') do |percent|
  @context_percent = percent
  @activity = nil
end

Given('daily allowance is ${int}') do |cap|
  ENV['CLAUDE_SPEND_CAP'] = cap.to_s
end

Given('${int} spent') do |spend|
  ActivityServer.set_response(
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

Given(/^(\d+) haiku at \$(\d+), (\d+) sonnet at \$(\d+), (\d+) opus at (\d+)\$ requests$/) do |haiku, haiku_cost, sonnet, sonnet_cost, opus, opus_cost|
  h = haiku.to_i
  hc = haiku_cost.to_i
  s = sonnet.to_i
  sc = sonnet_cost.to_i
  o = opus.to_i
  oc = opus_cost.to_i

  ActivityServer.set_response(
    {
      'results' => [
        {
          'metrics' => { 'spend' => h * hc + s * sc + o * oc },
          'breakdown' => {
            'models' => {
              'haiku' => { 'metrics' => { 'successful_requests' => h, 'spend' => h * hc } },
              'sonnet' => { 'metrics' => { 'successful_requests' => s, 'spend' => s * sc } },
              'opus' => { 'metrics' => { 'successful_requests' => o, 'spend' => o * oc } }
            }
          }
        }
      ]
    }
  )
end

Then(/^the "(Context|Spend|Models)" (bar|section) shows "(.+?)" in (\w+)$/) do |section_name, bar_or_section, expected, color|
  output = dude('status_line', stdin: status_json).strip
  expected_color = StatusLine::Format::COLORS[color.to_sym]
  cleaned = StatusLine::Format.strip(output)

  send("check_#{section_name.downcase}", cleaned, output, expected, expected_color, color)
end

def check_models(cleaned, output, expected, expected_color, color)
  expected_normalized = expected.gsub(' ', '').delete('[]')
  actual_models = extract_models_section(cleaned)
  raise "Expected Models '#{expected_normalized}' in cleaned output, got: #{actual_models}" unless actual_models == expected_normalized

  if expected.include?('[')
    match = expected.match(/\[([🐸🎭🎸][⁰¹²³⁴⁵⁶⁷⁸⁹]*)\]/)
    check_model_background(output, match[1][0], expected_color, color) if match
  else
    raise "Expected color #{color} in output" unless output.include?(expected_color)
  end
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
  bg_color = StatusLine::Format::BG_MAP[expected_color] || expected_color
  raise "Expected #{color_name} background for #{model_emoji}" unless output.include?(bg_color)
end
