module Specs
  module Helpers
    def strip(s)
      s.gsub(/\e\[[0-9;]*m/, '')
    end

    def capture_output
      old_stdout = $stdout
      old_stderr = $stderr
      $stdout = StringIO.new
      $stderr = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
end

RSpec.configure do |config|
  config.include Specs::Helpers
end
