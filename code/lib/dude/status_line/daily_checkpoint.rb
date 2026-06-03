require 'json'

module Dude
  module StatusLine
    class DailyCheckpoint
      def initialize(path = nil)
        @path = path || File.expand_path('~/.claude/status.json')
      end

      def read
        return {} unless File.exist?(@path)

        data = JSON.parse(File.read(@path))
        extract_checkpoint_fields(data)
      rescue StandardError
        {}
      end

      def write(month_total:, date:)
        data = read_all_fields
        data['daily_checkpoint_month_total'] = month_total
        data['daily_checkpoint_date'] = date
        File.write(@path, JSON.generate(data))
      end

      private

      def extract_checkpoint_fields(data)
        result = {}
        result[:daily_checkpoint_month_total] = data['daily_checkpoint_month_total'] if data.key?('daily_checkpoint_month_total')
        result[:daily_checkpoint_date] = data['daily_checkpoint_date'] if data.key?('daily_checkpoint_date')
        result
      end

      def read_all_fields
        return {} unless File.exist?(@path)

        JSON.parse(File.read(@path))
      rescue StandardError
        {}
      end
    end
  end
end
