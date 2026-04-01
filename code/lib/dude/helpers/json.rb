require 'json'

module Dude
  module Helpers
    module Json
      def read_json(path)
        JSON.load_file(path) rescue nil
      end

      def read_icon(path)
        return nil unless File.exist?(path)

        File.read(path)[/^---\s*\n(.*?\n)---\s*\n/m, 1]&.[](
          /^icon:\s*(.+)/,
          1
        )&.strip
      end
    end
  end
end
