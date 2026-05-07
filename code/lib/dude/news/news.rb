require_relative 'paperboy'
require_relative 'sommelier'

module Dude
  module News
    class News
      def initialize(limit: 5, paperboy: Paperboy.new,
        sommelier: Sommelier.new, taste: nil)
        @limit = limit
        @paperboy = paperboy
        @sommelier = sommelier
        @taste = taste
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
        smoke_test_lines(latest).each { |line| puts line }
      rescue => e
        puts "Error: #{e.message}"
      end

      def build_output_lines(latest)
        collect_sections(latest).flatten
      end

      def collect_sections(latest)
        [
          installed_and_latest_line(latest),
          releases_lines,
          smoke_test_lines(latest)
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

      def smoke_test_lines(latest)
        result = @sommelier.taste(latest, prompt: @taste)
        version = extract_version(latest)
        build_vintage_lines(version, result)
      end

      def extract_version(latest)
        latest.start_with?('v') ? latest[1..-1] : latest
      end

      def build_vintage_lines(version, result)
        lines = ["Vintage #{version}: #{result[:conclusion]}"]
        lines << result[:url] if result[:url]
        lines << result[:error] if result[:error]
        lines
      end
    end
  end
end
