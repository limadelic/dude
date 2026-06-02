require 'json'
require 'open3'

module Dude
  module StatusLine
    class AnthropicToken
      def self.fetch
        token_from_file || token_from_keychain
      end

      private

      def self.token_from_file
        creds_path = File.expand_path('~/.claude/.credentials.json')
        return nil unless File.exist?(creds_path)

        creds = JSON.parse(File.read(creds_path))
        creds.dig('claudeAiOauth', 'accessToken')
      rescue StandardError
        nil
      end

      def self.token_from_keychain
        out, _, status = Open3.capture3(
          'security', 'find-generic-password',
          '-s', 'Claude Code-credentials',
          '-w'
        )
        return '' unless status.success?

        creds = JSON.parse(out)
        creds.dig('claudeAiOauth', 'accessToken') || ''
      rescue StandardError
        ''
      end
    end
  end
end
