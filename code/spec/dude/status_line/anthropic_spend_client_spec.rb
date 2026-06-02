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
    it 'returns spend in dollars from API response' do
      stub(response_mock).body { JSON.generate({ 'extra_usage' => { 'used_credits' => 5000 } }) }

      spend = sut.fetch

      expect(spend).to eq(50.0)
    end

    it 'returns 0 when extra_usage missing' do
      stub(response_mock).body { JSON.generate({ 'data' => 'something' }) }

      spend = sut.fetch

      expect(spend).to eq(0)
    end

    it 'returns 0 when used_credits missing' do
      stub(response_mock).body { JSON.generate({ 'extra_usage' => { 'other_field' => 100 } }) }

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
