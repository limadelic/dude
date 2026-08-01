module PomoHelpers
  def verify_pomo_bar(bar, cleaned)
    msg = "Expected bar '#{bar}' in output, got: #{cleaned}"
    raise msg unless cleaned.include?(bar)
  end

  def verify_pomo_color(color_name, output, expected_color)
    msg = "Expected color #{color_name} in output"
    raise msg unless output.include?(expected_color)
  end
end
