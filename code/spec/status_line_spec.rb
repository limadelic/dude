require_relative 'spec_helper'
require_relative '../lib/dude/status_line/runner'
require_relative 'examples/shared'

describe Dude::StatusLine::Runner do
  include_context 'StatusLine helpers'

  before do
    allow(Dude::StatusLine::Dudes).to receive(:new).and_return(mock_renderer)
    allow(Dude::Pomo::Pomo).to receive(:new).and_return(mock_pomo)
    allow(Open3).to receive(:capture3).and_return(mock_curl_response)
  end

  let(:mock_renderer) do
    instance_double(Dude::StatusLine::Dudes, to_s: '🎭', write_status: nil)
  end

  let(:mock_pomo) do
    instance_double(Dude::Pomo::Pomo, to_s: nil)
  end

  let(:mock_curl_response) do
    [activity.to_json, '', double(success?: true)]
  end

  describe 'Structure and order' do
    it 'has sections' do
      output = out(session, activity)
      expect(strip(output)).to match(/🧠.*💰.*[🎭🎸🐸]/)
    end

    it 'has correct order' do
      output = out(session, activity)
      expect(strip(output).index("🧠")).to be < strip(output).index("💰")
    end
  end

  describe 'Error handling' do
    it 'handles invalid JSON input' do
      output = out('bad', activity)
      expect(output).not_to be_empty
    end

    it 'handles empty JSON' do
      output = out('{}', activity)
      expect(output).not_to be_empty
    end
  end

  describe 'API contract' do
    it 'fetches JSON from API when activity not passed' do
      runner = Dude::StatusLine::Runner.new('{}')
      runner.send(:activity_data)
      expect(Open3).to have_received(:capture3).with(
        'curl', '-s', '-L', anything, anything, anything, anything, anything
      )
    end

    it 'uses passed activity without API call' do
      out(session, activity)
      expect(Open3).not_to have_received(:capture3)
    end

    it 'has expected activity_data structure' do
      runner = Dude::StatusLine::Runner.new('{}', activity: activity)
      raw = runner.send(:activity_data)
      expect(raw.dig('results', 0, 'metrics', 'spend')).to be_truthy
      expect(raw.dig('results', 0, 'breakdown', 'models')).to be_truthy
    end
  end
end
