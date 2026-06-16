require 'json'

module Dude
  module StatusLine
    class DailyCheckpoint
      def initialize(path = nil)
        @path = path || File.expand_path('~/.claude/status.json')
      end

      def read
        data = read_all
        extract_checkpoint_fields(data)
      end

      def write(spent:, date:, month_spend_at_day_start: nil, days_left: nil)
        data = read_all
        data['spent'] = spent
        data['date'] = date
        data['month_spend_at_day_start'] = month_spend_at_day_start if month_spend_at_day_start
        data['days_left'] = days_left if days_left
        tmp = @path + '.tmp'
        File.write(tmp, JSON.generate(data))
        File.rename(tmp, @path)
      end

      private

      def read_all
        return {} unless File.exist?(@path)

        JSON.parse(File.read(@path))
      rescue StandardError
        {}
      end

      def extract_checkpoint_fields(data)
        result = {}
        result[:spent] =
          data['spent'] if data.key?('spent')
        result[:date] =
          data['date'] if data.key?('date')
        result[:month_spend_at_day_start] =
          data['month_spend_at_day_start'] if data.key?('month_spend_at_day_start')
        result[:days_left] =
          data['days_left'] if data.key?('days_left')
        result
      end
    end
  end
end
