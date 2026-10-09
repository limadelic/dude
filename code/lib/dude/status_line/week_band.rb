require_relative 'window_band'

module Dude
  module StatusLine
    class WeekBand < WindowBand
      def initialize(session_data, cache: nil, registry: nil,
        cache_path: nil)
        super(
          session_data,
          window: '7d',
          cache: cache,
          registry: registry,
          cache_path: cache_path
        )
      end
    end
  end
end
