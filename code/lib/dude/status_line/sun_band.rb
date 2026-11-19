require_relative 'window_band'

module Dude
  module StatusLine
    class SunBand < WindowBand
      def initialize(session_data, cache: nil, registry: nil,
        cache_path: nil)
        super(
          session_data,
          window: '5h',
          cache: cache,
          registry: registry,
          cache_path: cache_path
        )
      end
    end
  end
end
