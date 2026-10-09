module Dude
  module Transcript
    class Band
      YELLOW_THRESHOLD = 2
      RED_THRESHOLD = 3

      def initialize(ratio, active_count)
        @ratio = ratio
        @active_count = active_count
      end

      def color
        return nil if @ratio.nil? || @active_count <= 1
        return :red if @ratio >= RED_THRESHOLD
        return :yellow if @ratio >= YELLOW_THRESHOLD
      end
    end
  end
end
