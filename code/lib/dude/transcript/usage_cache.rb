module Dude
  module Transcript
    class UsageCache
      def initialize(price_table)
        @price_table = price_table
        @files = {}
        @windows = {}
      end

      def add(window_name, record)
        return if record[:epoch] < window_start(window_name)
        return if has_seen_id?(window_name, record[:id])

        add_to_window(window_name, record)
      end

      def set_window_start(window_name, start_epoch)
        existing = window_start(window_name)
        reset_window(window_name, start_epoch) if existing != start_epoch
        @windows[window_name] ||= new_window(start_epoch)
      end

      def window_start(window_name)
        @windows.dig(window_name, :start) || Float::INFINITY
      end

      def cost(window_name, session_id)
        @windows.dig(window_name, :costs, session_id) || 0
      end

      def has_seen_id?(window_name, id)
        @windows.dig(window_name, :seen_ids)&.include?(id) || false
      end

      def set_file_state(file_path, mtime, offset)
        @files[file_path] = [mtime, offset]
      end

      def file_state(file_path)
        @files[file_path]
      end

      def to_h
        {
          files: @files.dup,
          windows: windows_dump
        }
      end

      def from_h(hash_data)
        @files = hash_data[:files].dup
        @windows = windows_load(hash_data[:windows])
      end

      private

      def add_to_window(window_name, record)
        window = ensure_window(window_name)
        cost = @price_table.cost(record[:model], record[:usage])
        session = record[:session]
        window[:costs][session] = (window[:costs][session] || 0) + cost
        window[:seen_ids].add(record[:id])
      end

      def ensure_window(window_name)
        @windows[window_name] ||= new_window(Float::INFINITY)
      end

      def new_window(start)
        { start: start, costs: {}, seen_ids: Set.new }
      end

      def reset_window(window_name, start_epoch)
        @windows[window_name] = new_window(start_epoch)
      end

      def windows_dump
        @windows.each_with_object({}) do |(name, data), acc|
          acc[name] = {
            start: data[:start],
            costs: data[:costs].dup,
            seen_ids: data[:seen_ids].dup
          }
        end
      end

      def windows_load(windows_hash)
        windows_hash.each_with_object({}) do |(name, data), acc|
          acc[name] = {
            start: data[:start],
            costs: data[:costs].dup,
            seen_ids: Set.new(data[:seen_ids])
          }
        end
      end
    end
  end
end
