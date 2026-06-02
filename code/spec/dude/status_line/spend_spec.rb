require_relative '../../spec_helper'
require 'dude/status_line/spend'

describe Dude::StatusLine::Spend do
  include RR::DSL
  let(:sut) { described_class.new(token_fetcher, client, cache) }
  let(:token_fetcher) { Object.new }
  let(:client) { Object.new }
  let(:cache) { Object.new }

  before do
    allow_message_expectations_on_nil
  end

  describe '#to_s' do
    it 'shows green bar when daily rate below 33%' do
      stub(token_fetcher).fetch { 'token' }
      stub(cache).fetch { 10.0 }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }

      output = sut.to_s

      expect(output).to include("\033[32m")
      expect(output).to include('💰')
      expect(output).to include('█')
    end

    it 'calculates daily rate as monthly_spend / day_of_month' do
      stub(token_fetcher).fetch { 'token' }
      stub(cache).fetch { 100.0 }
      stub(client).fetch { 100.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }

      output = sut.to_s

      daily_rate = 100.0 / 15
      expected_pct = (daily_rate / 8.75 * 100).round
      expect(expected_pct).to eq(76)
      expect(output).to include('█')
    end

    it 'shows yellow bar when daily rate 33-66%' do
      stub(token_fetcher).fetch { 'token' }
      stub(cache).fetch { 50.0 }
      stub(client).fetch { 50.0 }
      stub(Time).now { Time.new(2026, 6, 10, 0, 0, 0) }

      output = sut.to_s

      expect(output).to include("\033[38;5;226m")
    end

    it 'shows red bar when daily rate above 66%' do
      stub(token_fetcher).fetch { 'token' }
      stub(cache).fetch { 150.0 }
      stub(client).fetch { 150.0 }
      stub(Time).now { Time.new(2026, 6, 5, 0, 0, 0) }

      output = sut.to_s

      expect(output).to include("\033[31m")
    end

    it 'shows empty bar when no token available' do
      stub(token_fetcher).fetch { '' }

      output = sut.to_s

      expect(output).to include('💰')
      expect(output).to include('░░░░░░░░░')
    end

    it 'shows empty bar when API fails' do
      stub(token_fetcher).fetch { 'token' }
      stub(cache).fetch { 0.0 }
      stub(client).fetch { 0.0 }

      output = sut.to_s

      expect(output).to include('░░░░░░░░░')
    end
  end
end
