module Dude
  module Transcript
    class Deduper
      def call(records)
        records
          .reject { |record| record[:id].nil? }
          .reduce({}) do |by_id, record|
            id = record[:id]
            by_id[id] =
              record if by_id[id].nil? || record[:epoch] < by_id[id][:epoch]
            by_id
          end
          .values
          .sort_by { |record| record[:epoch] }
      end
    end
  end
end
