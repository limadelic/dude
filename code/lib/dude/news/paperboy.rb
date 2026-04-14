require_relative '../helpers/gh'

module Dude
  module News
    class Paperboy
      def initialize(gh: Dude::Helpers::Gh.new)
        @gh = gh
      end

      def latest_version
        opts = "--limit 1 --json tagName -q '.[0].tagName'"
        @gh.run("release list -R anthropics/claude-code #{opts}")
      end

      def releases(limit)
        output = @gh.run(releases_cmd(limit))
        tags = output.split("\n").reject(&:empty?).take(limit)
        tags.map { |tag| {tag: tag, body: release_body(tag)} }
      end

      def release_body(tag)
        @gh.run("release view #{tag} -R anthropics/claude-code --json body -q '.body'")
      end

      private

      def releases_cmd(limit)
        opts = "--json tagName -q '.[].tagName'"
        "release list -R anthropics/claude-code --limit #{limit} #{opts}"
      end
    end
  end
end
