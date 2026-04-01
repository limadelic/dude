require 'json'

module Dude
  module Dudes
    class Inbox
      def initialize(path, data = [])
        @path = path
        @data = data
        @items = nil
      end

      def length
        items.length
      end

      def append(message)
        items.push(message)
        flush
      end

      def mark_wip
        return if items.empty?

        items[0]['status'] = 'wip'
        flush
      end

      def dequeue_wip
        return unless items[0]&.[]('status') == 'wip'

        items.shift
        flush
      end

      def first_new
        return nil unless File.exist?(@path)

        items.find { |i| i['status'] == 'new' }
      end

      private

      def items
        @items ||= read_json || []
      end

      def read_json
        JSON.load_file(@path) rescue nil
      end

      def flush
        write_json(items)
      end

      def write_json(data)
        File.write(@path, data.to_json)
      end
    end
  end
end
