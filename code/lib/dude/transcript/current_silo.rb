module Dude
  module Transcript
    class CurrentSilo
      def initialize(registry)
        @registry = registry
      end

      def call(session_name: nil, customTitle: nil, agentName: nil)
        [session_name, customTitle, agentName].reduce(nil) do |result, name|
          result || (@registry.silo_id(name) if name && !name.empty?)
        end
      end
    end
  end
end
