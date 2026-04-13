require_relative 'spec_helper'
require_relative '../lib/dude/status_line/runner'
require_relative 'examples/shared'

describe Dude::StatusLine::Runner do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:sut) { Dude::StatusLine::Runner.new(session_input, activity: activity_data, dudes: dudes_data) }
  let(:dudes_instance) { Object.new }
  let(:pomo_instance) { Object.new }
  let(:session_input) { session }
  let(:activity_data) { activity }
  let(:dudes_data) { nil }

  before do
    stub(Dude::StatusLine::Dudes).new { dudes_instance }
    stub(dudes_instance).write_status { nil }
    stub(dudes_instance).to_s { '🎭' }
    stub(pomo_instance).to_s { nil }
    stub(Dude::Pomo::Pomo).new { pomo_instance }
  end

  describe 'Structure and order' do
    it 'includes brain context section' do
      output = capture_output { sut.run }

      expect(strip(output)).to include('🧠')
    end

    it 'includes spend section' do
      output = capture_output { sut.run }

      expect(strip(output)).to include('💰')
    end

    it 'includes dudes section' do
      output = capture_output { sut.run }

      expect(strip(output)).to include('🎭')
    end

    it 'has context before spend' do
      output = capture_output { sut.run }
      stripped = strip(output)

      expect(stripped.index('🧠')).to be < stripped.index('💰')
    end
  end

  describe 'Error handling' do
    context 'with invalid JSON input' do
      let(:session_input) { 'bad' }

      it 'handles gracefully' do
        output = capture_output { sut.run }

        expect(output).not_to be_empty
      end
    end

    context 'with empty JSON' do
      let(:session_input) { '{}' }

      it 'handles gracefully' do
        output = capture_output { sut.run }

        expect(output).not_to be_empty
      end
    end
  end
end
