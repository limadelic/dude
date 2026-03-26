module Helpers
  class Wait
    Timeout = Class.new(StandardError)

    def initialize(interval: 1, timeout: nil)
      @interval = interval
      @timeout = timeout
    end

    def until(&block)
      deadline = @timeout ? Time.now + @timeout : nil
      loop do
        return true if block.call
        check_deadline(deadline)
        sleep @interval
      end
    end

    private

    def check_deadline(deadline)
      return unless deadline
      raise Timeout, 'wait timed out' if Time.now >= deadline
    end
  end
end
