module DudesHelpers
  def stub_backticks(mocks)
    allow_any_instance_of(Object).to receive(:`) do |_receiver, cmd|
      match = mocks.find { |pattern, _| pattern_matches?(pattern, cmd) }
      match ? match[1] : ''
    end
  end

  def pattern_matches?(pattern, cmd)
    pattern.split.all? { |word| cmd.include?(word) }
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    ensure_stdout_restored(original)
  end

  def ensure_stdout_restored(original)
    $stdout.string.chomp
  ensure
    $stdout = original
  end

  def verify_table(table)
    table.raw.flatten.each { |row| verify_row(row.strip) }
  end

  def verify_row(row)
    is_negative = row.start_with?('(') && row.end_with?(')')
    is_negative ? verify_negative(row[1..-2]) : verify_positive(row)
  end

  def verify_positive(expected)
    @mocks ? verify_mocks_match(expected) : verify_output_match(expected)
  end

  def verify_mocks_match(expected)
    msg = "Expected '#{expected}' in output:\n#{@output}"
    raise msg unless @output.include?(expected)
  end

  def verify_output_match(expected)
    wait_for("shows #{expected}") { show_expected_parts?(expected) }
  end

  def show_expected_parts?(expected)
    output = dude('status_line').strip
    expected.split.all? { |part| output.include?(part) }
  end

  def verify_negative(val)
    @mocks ? verify_mocks_exclude(val) : verify_status_exclude(val)
  end

  def verify_mocks_exclude(val)
    msg = "Not expected '#{val}' in output:\n#{@output}"
    raise msg if @output.include?(val)
  end

  def verify_status_exclude(val)
    output = dude('status_line').strip
    msg = "Not expected '#{val}' in status line:\n#{output}"
    raise msg if output.include?(val)
  end

  def verify_shell_output(cmd, expected, output)
    msg = "Expected '#{expected}' in output of '#{cmd}':\n#{output}"
    raise msg unless output.include?(expected)
  end
end
