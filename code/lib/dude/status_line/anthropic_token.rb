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

        extract_token(JSON.parse(File.read(creds_path)))
      rescue StandardError
        nil
      end

      def self.token_from_keychain
        out, _, status = capture_keychain
        return '' unless status.success?

        extract_token(JSON.parse(out)) || ''
      rescue StandardError
        ''
      end

      def self.capture_keychain
        Open3.capture3(
          'security', 'find-generic-password',
          '-s', 'Claude Code-credentials',
          '-w'
        )
      end

      def self.extract_token(creds)
        creds.dig('claudeAiOauth', 'accessToken')
      end
    end
  end
end
