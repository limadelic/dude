require_relative 'format'

module Dude
  module StatusLine
    class Context
      include Dude::StatusLine::Format

      def initialize(session, context_percentage)
        @session = session
        @context_percentage = context_percentage
      end

      def to_s
        bar(@context_percentage, '🧠', lo: 33, hi: 66)
      end
    end
  end
end
