require_relative 'paperboy'

module Dude
  module News
    class News
      def initialize(limit: 5, paperboy: Paperboy.new)
        @limit = limit
        @paperboy = paperboy
      end

      def fetch
        latest = @paperboy.latest_version
        lines = build_output_lines(latest)
        lines.join("\n")
      end

      def run
        latest = @paperboy.latest_version
        puts installed_and_latest_line(latest)
        releases_lines.each { |line| puts line }
      rescue => e
        puts "Error: #{e.message}"
      end

      def build_output_lines(latest)
        collect_sections(latest).flatten
      end

      def collect_sections(latest)
        [
          installed_and_latest_line(latest),
          releases_lines
        ]
      end

      private

      def installed_version
        @installed_version ||= `claude --version`.strip
      end

      def installed_and_latest_line(latest)
        installed = installed_version
        "Installed: #{installed}, Latest: #{latest}"
      end

      def releases_lines
        @paperboy.releases(@limit).map do |release|
          [release[:tag], release[:body]]
        end.flatten
      end
    end
  end
end
