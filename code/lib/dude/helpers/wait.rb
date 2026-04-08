module Dude
  module Helpers
    class Wait
      Timeout = Class.new(StandardError)

      def initialize(interval: 1, timeout: nil)
        @interval = interval
        @timeout = timeout
        @start_time = Time.now
      end

      def until(&block)
        loop do
          return true if block.call
          raise Timeout if expired?

          sleep @interval
        end
      end

      private

      def expired?
        @timeout && Time.now - @start_time >= @timeout
      end
    end
  end
end
