require 'net/http'
require 'json'
require 'uri'

module Dude
  module StatusLine
    class AnthropicSpendClient
      API_URL = 'https://api.anthropic.com/api/oauth/usage'

      def initialize(token, http_factory = nil)
        @token = token
        @http_factory = http_factory || method(:default_http_factory)
      end

      def fetch
        uri = URI(API_URL)
        http = @http_factory.call(uri)
        req = Net::HTTP::Get.new(uri.path)
        req['Authorization'] = "Bearer #{@token}"
        req['anthropic-version'] = '2023-06-01'
        req['Content-Type'] = 'application/json'

        response = http.request(req)
        parse_response(response)
      rescue StandardError
        0
      end

      private

      def default_http_factory(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http
      end

      def parse_response(response)
        data = JSON.parse(response.body)
        extra = data.dig('extra_usage') || {}
        used_credits = extra['used_credits'] || 0
        used_credits / 100.0
      end
    end
  end
end
