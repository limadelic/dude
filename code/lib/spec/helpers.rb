module Spec
  module Helpers
    def strip(s)
      s.gsub(/\e\[[0-9;]*m/, '')
    end

    def capture_output
      old = [$stdout, $stderr];
      $stdout = $stderr = StringIO.new; yield; $stdout.string
    ensure
      $stdout, $stderr = old
    end
  end
end

RSpec.configure do |config|
  config.include Spec::Helpers
end
