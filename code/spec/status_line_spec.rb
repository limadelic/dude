require_relative 'spec_helper'
require_relative '../lib/status_line'

describe StatusLine::Runner do
  include_context 'StatusLine helpers'

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
    it 'has expected activity_data structure' do
      runner = StatusLine::Runner.new('{}')
      raw = runner.send(:activity_data)
      expect(raw.dig('results', 0, 'metrics', 'spend')).to be_truthy
      expect(raw.dig('results', 0, 'breakdown', 'models')).to be_truthy
    end
  end
end
