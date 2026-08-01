require 'time'
require_relative 'anthropic_token'
require_relative 'anthropic_spend_client'
require_relative 'spend'

module Dude
  module StatusLine
    module SpendSection
      class MemoizedTokenFetcher
        def initialize(token)
          @token = token
        end

        def fetch
          @token
        end
      end

      def spend_section(token)
        c = Dude::StatusLine::AnthropicSpendClient
        tf = MemoizedTokenFetcher.new(token)
        Dude::StatusLine::Spend.new(tf, c.new(token)).to_s
      end
    end
  end
end
