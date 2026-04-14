module Cuke
  module AlleyPr
    def set_current_branch(branch_name)
      @current_branch = branch_name
    end

    def current_branch
      @current_branch || 'main'
    end

    def run_alley_pr
      @error = nil
      AlleyPrRunner.new(self).execute
    rescue => e
      @error = e
    end

    def error_message
      @error&.message || ''
    end

    class AlleyPrRunner
      def initialize(world)
        @world = world
      end

      def execute
        if @world.current_branch == 'main'
          raise "Cannot run alley-pr on main branch"
        end
      end
    end
  end
end
