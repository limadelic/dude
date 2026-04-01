require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/models'
require_relative '../../lib/dude/dudes/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Models do
  include_context 'StatusLine helpers'

  before do
    allow(Dude::Dudes::Dudes).to receive(:new).and_return(
      instance_double(
        Dude::Dudes::Dudes, all: []
      )
    )
  end

  describe 'Active model background' do
    it 'is red for opus' do
      expect(output_for_model('opus')).to include("\e[41m")
    end

    it 'is green for sonnet' do
      expect(output_for_model('sonnet')).to include("\e[42m")
    end

    it 'is green for haiku' do
      expect(output_for_model('haiku')).to include("\e[42m")
    end

    it 'has white text on red' do
      expect(output_for_model('opus')).to include("\e[41m\e[97m")
    end

    it 'has white text on green' do
      expect(output_for_model('sonnet')).to include("\e[42m\e[97m")
    end

    it 'has black text on yellow for readability' do
      session_data = mock_session('opus', 50)
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
      activity_data = mock_activity(models: models)
      output = out(session_data.to_json, activity_data)
      expect(output).to include("\e[48;5;226m\e[30m")
    end
  end

  describe 'Model order' do
    it 'is sorted by requests' do
      output = out(session, activity)
      expect(strip(output)).to match(/🐸.*🎭.*🎸/)
    end
  end

  describe 'Model multiplier' do
    it 'shows superscript for all models' do
      output = out(session, activity)
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
      output = output_with_models(models)
      expect(output).to match(/🎭 ?¹⁰/)
    end

    it 'shows no models with zero requests' do
      models = {}
      output = output_with_models(models)
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
      output = output_with_models(models)
      expect(output).to match(/🎭 ?¹⁰/)
      expect(output).to match(/🐸 ?⁰/)
      expect(output).to match(/🎸 ?⁰/)
    end
  end

  private

  def output_for_model(model_name)
    session_data = mock_session(model_name, 25)
    out(session_data.to_json, activity)
  end

  def output_with_models(models)
    activity_data = mock_activity(models: models)
    session_data = mock_session('opus', 25)
    strip(out(session_data.to_json, activity_data))
  end
end
