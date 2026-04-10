require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/models'
require_relative '../../lib/dude/dudes/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Models do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:dudes_double) { Object.new }

  before do
    stub(dudes_double).all { [] }
    stub(Dude::Dudes::Dudes).new { dudes_double }
  end

  describe 'Active model background' do
    let(:activity_data) { mock_activity }

    it 'is red for opus' do
      session_data = mock_session('opus', 25)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[41m")
    end

    it 'is green for sonnet' do
      session_data = mock_session('sonnet', 25)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[42m")
    end

    it 'is green for haiku' do
      session_data = mock_session('haiku', 25)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[42m")
    end

    it 'has white text on red' do
      session_data = mock_session('opus', 25)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[41m\e[97m")
    end

    it 'has white text on green' do
      session_data = mock_session('sonnet', 25)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[42m\e[97m")
    end

    it 'has black text on yellow for readability' do
      models = {
        'claude-haiku-4-5' => {
          'metrics' => {
            'successful_requests' => 40,
            'spend' => 5.0
          }
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
      session_data = mock_session('opus', 50)
      activity_data = mock_activity(models: models)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[48;5;226m\e[30m")
    end
  end

  describe 'Model order' do
    let(:session_data) { mock_session('opus', 25).to_json }
    let(:activity_data) { mock_activity }

    it 'is sorted by requests' do
      output = out(session_data, activity_data)
      expect(strip(output)).to match(/🐸.*🎭.*🎸/)
    end
  end

  describe 'Model multiplier' do
    let(:session_data) { mock_session('opus', 25).to_json }
    let(:activity_data) { mock_activity }

    it 'shows superscript for all models' do
      output = out(session_data, activity_data)
      expect(strip(output)).to match(/[²³⁴⁵⁶⁷⁸⁹]/)
    end

    it 'shows ¹⁰ for model with 1 request' do
      models = {
        'claude-opus-4-6' => {
          'metrics' => {
            'successful_requests' => 1, 'spend' => 1.0
          }
        }
      }
      activity_data = mock_activity(models: models)
      output = strip(out(session_data, activity_data))
      expect(output).to match(/🎭 ?¹⁰/)
    end

    it 'shows no models with zero requests' do
      models = {}
      activity_data = mock_activity(models: models)
      output = strip(out(session_data, activity_data))
      expect(output).not_to match(/[🐸🎭🎸]/)
    end

    it 'shows all models with superscripts for single model' do
      models = {
        'claude-opus-4-6' => {
          'metrics' => {
            'successful_requests' => 50, 'spend' => 5.0
          }
        }
      }
      activity_data = mock_activity(models: models)
      output = strip(out(session_data, activity_data))
      expect(output).to match(/🎭 ?¹⁰/)
      expect(output).to match(/🐸 ?⁰/)
      expect(output).to match(/🎸 ?⁰/)
    end
  end

end
