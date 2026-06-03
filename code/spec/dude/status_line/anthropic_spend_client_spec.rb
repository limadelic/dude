require_relative '../../spec_helper'
require 'dude/status_line/anthropic_spend_client'

describe Dude::StatusLine::AnthropicSpendClient do
  include RR::DSL
  let(:http_mock) { Object.new }
  let(:response_mock) { Object.new }
  let(:http_factory) { proc { http_mock } }
  let(:sut) { described_class.new(token, http_factory) }
  let(:token) { 'test_token' }

  before do
    stub(http_mock).request(anything) { response_mock }
  end

  describe '#fetch' do
    it 'sets User-Agent header' do
      verify = proc do |req|
        expect(req['User-Agent']).to eq('claude-code/latest')
        response_mock
      end
      stub(http_mock).request { |req| verify.call(req) }
      stub(response_mock).body do
        JSON.generate({ 'extra_usage' => { 'used_credits' => 5000 } })
      end

      sut.fetch
    end

    it 'returns spend in dollars from API response' do
      body = { 'extra_usage' => { 'used_credits' => 5000 } }
      stub(response_mock).body { JSON.generate(body) }

      spend = sut.fetch

      expect(spend).to eq(50.0)
    end

    it 'returns 0 when extra_usage missing' do
      stub(response_mock).body { JSON.generate({ 'data' => 'something' }) }

      spend = sut.fetch

      expect(spend).to eq(0)
    end

    it 'returns 0 when used_credits missing' do
      body = { 'extra_usage' => { 'other_field' => 100 } }
      stub(response_mock).body { JSON.generate(body) }

      spend = sut.fetch

      expect(spend).to eq(0)
    end

    it 'returns 0 when API call fails' do
      stub(http_mock).request { raise StandardError, 'network error' }

      spend = sut.fetch

      expect(spend).to eq(0)
    end
  end
end
