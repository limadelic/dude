module Dude
  module StatusLine
    class UsageWindow
      def initialize(window_entry, window_len:, now: nil)
        @window_entry = window_entry
        @window_len = window_len
        @now = now || Time.now.to_i
      end

      def range
        return nil unless @window_entry&.dig('resets_at')

        start_time = @window_entry['resets_at'] - @window_len
        end_time = @now

        [start_time, end_time]
      end
    end
  end
end
