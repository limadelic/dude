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
        return nil if @ratio.nil?
        return nil if @active_count <= 1

        case @ratio
        when 0...YELLOW_THRESHOLD
          nil
        when YELLOW_THRESHOLD...RED_THRESHOLD
          :yellow
        else
          :red
        end
      end
    end
  end
end
