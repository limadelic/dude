require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/models'
require_relative '../examples/shared'

describe Dude::StatusLine::Models do
  include RR::DSL
  include_context 'StatusLine helpers'

  def strip(s)
    s.gsub(/\e\[[0-9;]*m/, '')
  end

  let(:session) { mock_session('opus', 25) }
  let(:activity) { mock_activity }
  let(:sut) { Dude::StatusLine::Models.new(session, activity) }

  describe 'Active model background' do
    context 'when using opus' do
      let(:session) { mock_session('opus', 25) }

      it 'is red' do
        expect(sut.to_s).to include("\e[41m")
      end

      it 'has white text' do
        expect(sut.to_s).to include("\e[41m\e[97m")
      end
    end

    context 'when using sonnet' do
      let(:session) { mock_session('sonnet', 25) }

      it 'is green' do
        expect(sut.to_s).to include("\e[42m")
      end

      it 'has white text' do
        expect(sut.to_s).to include("\e[42m\e[97m")
      end
    end

    context 'when using haiku' do
      let(:session) { mock_session('haiku', 25) }

      it 'is green' do
        expect(sut.to_s).to include("\e[42m")
      end
    end

    context 'when multiple models have high request counts' do
      let(:activity) do
        mock_activity(
          models: {
            'claude-haiku-4-5' => {
              'metrics' => { 'successful_requests' => 40, 'spend' => 5.0 }
            },
            'claude-opus-4-6' => {
              'metrics' => {
                'successful_requests' => 30,
                'spend' => 5.0
              }
            },
            'claude-sonnet-4-6' => {
              'metrics' => {
                'successful_requests' => 30,
                'spend' => 5.0
              }
            }
          }
        )
      end
      let(:session) { mock_session('opus', 50) }

      it 'has black text on yellow for readability' do
        expect(sut.to_s).to include("\e[48;5;226m\e[30m")
      end
    end
  end

  describe 'Model order' do
    it 'is sorted by requests' do
      expect(strip(sut.to_s)).to match(/🐸.*🎭.*🎸/)
    end
  end

  describe 'Model multiplier' do
    it 'shows superscript for all models' do
      expect(strip(sut.to_s)).to match(/[²³⁴⁵⁶⁷⁸⁹]/)
    end

    context 'when model has 1 request' do
      let(:activity) do
        mock_activity(
          models: {
            'claude-opus-4-6' => {
              'metrics' => { 'successful_requests' => 1, 'spend' => 1.0 }
            }
          }
        )
      end

      it 'shows ¹⁰ for that model' do
        expect(strip(sut.to_s)).to match(/🎭 ?¹⁰/)
      end
    end

    context 'when no models have requests' do
      let(:activity) { mock_activity(models: {}) }

      it 'shows no models' do
        expect(strip(sut.to_s)).not_to match(/[🐸🎭🎸]/)
      end
    end

    context 'when only one model has requests' do
      let(:activity) do
        mock_activity(
          models: {
            'claude-opus-4-6' => {
              'metrics' => { 'successful_requests' => 50, 'spend' => 5.0 }
            }
          }
        )
      end

      it 'shows opus with superscript' do
        expect(strip(sut.to_s)).to match(/🎭 ?¹⁰/)
      end

      it 'shows haiku with zero superscript' do
        expect(strip(sut.to_s)).to match(/🐸 ?⁰/)
      end

      it 'shows sonnet with zero superscript' do
        expect(strip(sut.to_s)).to match(/🎸 ?⁰/)
      end
    end
  end
end
