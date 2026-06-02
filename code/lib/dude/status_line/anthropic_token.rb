require 'json'

module Dude
  module StatusLine
    class AnthropicToken
      def self.fetch
        creds_path = File.expand_path('~/.claude/.credentials.json')
        return '' unless File.exist?(creds_path)

        creds = JSON.parse(File.read(creds_path))
        creds.dig('claudeAiOauth', 'accessToken') || ''
      rescue StandardError
        ''
      end
    end
  end
end
