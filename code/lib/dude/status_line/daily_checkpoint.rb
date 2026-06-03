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

      def write(month_total:, date:)
        data = read_all
        data['daily_checkpoint_month_total'] = month_total
        data['daily_checkpoint_date'] = date
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
        result[:daily_checkpoint_month_total] =
          data['daily_checkpoint_month_total'] if data.key?('daily_checkpoint_month_total')
        result[:daily_checkpoint_date] =
          data['daily_checkpoint_date'] if data.key?('daily_checkpoint_date')
        result
      end
    end
  end
end
