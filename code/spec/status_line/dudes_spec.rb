require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Dudes do
  include_context 'StatusLine helpers'

  def mock_dude(name:, icon:, messages:, context:, current:, abiding: true)
    d = double(name)
    allow(d).to receive_messages(
      name: name, icon: icon, messages: messages,
      context: context, is_current?: current, is_abiding?: abiding
    )
    d
  end

  let(:dudes_data) do
    [
      mock_dude(
        name: 'dude', icon: '🎳', messages: 0, context: 25, current: true
      ),
      mock_dude(
        name: 'rec', icon: '🔴', messages: 3, context: 50, current: false
      ),
      mock_dude(
        name: 'smith', icon: '🤖', messages: 0, context: 80, current: false
      )
    ]
  end

  describe 'Dudes section' do
    it 'shows dude icons' do
      output = out(session, activity, dudes_data)
      expect(strip(output)).to include('🎳', '🔴', '🤖')
    end

    it 'shows message count superscript' do
      output = out(session, activity, dudes_data)
      expect(strip(output)).to match(/🔴 ?³/)
    end

    it 'shows zero superscript' do
      output = out(session, activity, dudes_data)
      expect(strip(output)).to match(/🎳 ?⁰/)
    end

    it 'appears after models' do
      output = out(session, activity, dudes_data)
      expect(strip(output).index('🎭')).to be < strip(output).index('🎳')
    end

    it 'highlights current dude with background' do
      output = out(session, activity, dudes_data)
      expect(output).to include("\e[42m\e[97m🎳")
    end

    it 'does not highlight non-current dude' do
      output = out(session, activity, dudes_data)
      expect(output).not_to include("\e[42m\e[97m🔴")
    end

    it 'highlights current yellow dude with black text' do
      yellow_dudes = [
        mock_dude(
          name: 'dude', icon: '🎳', messages: 0, context: 50, current: true
        )
      ]
      session_data = {
        'model' => { 'id' => 'claude-opus-4-6' },
        'context_window' => { 'used_percentage' => 50 }
      }.to_json
      output = out(session_data, activity, yellow_dudes)
      expect(output).to include("\e[48;5;226m\e[30m🎳")
    end
  end

  describe 'Abide watcher status' do
    context 'not abiding' do
      it 'shows ˣ with context color' do
        dudes = [
          mock_dude(
            name: 'rec', icon: '🔴', messages: 3, context: 50,
            current: false, abiding: false
          )
        ]
        output = out(session, activity, dudes)
        expect(output).to include("\e[38;5;226m🔴", "ˣ")
      end

      it 'shows green ˣ with low context' do
        dudes = [
          mock_dude(
            name: 'rec', icon: '🔴', messages: 0, context: 10,
            current: false, abiding: false
          )
        ]
        output = out(session, activity, dudes)
        expect(output).to include("\e[32m🔴", "ˣ")
      end

      it 'has background highlight for current not-abiding dude' do
        dudes = [
          mock_dude(
            name: 'rec', icon: '🔴', messages: 0, context: 25,
            current: true, abiding: false
          )
        ]
        output = out(session, activity, dudes)
        expect(output).to include("\e[42m\e[97m🔴", "ˣ")
      end

      it 'shows red ˣ with high context' do
        dudes = [
          mock_dude(
            name: 'rec', icon: '🔴', messages: 0, context: 80,
            current: false, abiding: false
          )
        ]
        output = out(session, activity, dudes)
        expect(output).to include("\e[31m🔴", "ˣ")
      end
    end

    context 'abiding' do
      it 'shows message count' do
        dudes = [
          mock_dude(
            name: 'rec', icon: '🔴', messages: 3, context: 50,
            current: false, abiding: true
          )
        ]
        output = out(session, activity, dudes)
        expect(strip(output)).to match(/🔴 ?³/)
      end
    end
  end

  describe '#write_status' do
    let(:pct) { 50 }
    let(:dudes) { Dude::StatusLine::Dudes.new({}, nil, '/tmp', pct) }

    before do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(JSON).to receive(:load_file) { {} }
      allow(File).to receive(:write)
    end

    context 'context color' do
      context_percentages = {
        0 => 'green', 32 => 'green', 33 => 'yellow', 66 => 'yellow',
        67 => 'red', 100 => 'red'
      }
      context_percentages.each do |p, c|
        it "writes #{c} at #{p}%" do
          d = Dude::StatusLine::Dudes.new({}, nil, '/tmp', p)
          allow(Dir).to receive(:exist?).and_return(true)
          allow(JSON).to receive(:load_file) { {} }
          allow(File).to receive(:write)
          d.write_status
          expect(File).to have_received(:write).with(
            anything, include("\"color\":\"#{c}\"")
          )
        end
      end
    end
  end

  describe 'initialization' do
    it 'recovers from invalid JSON in session_data' do
      original_parse = JSON.method(:parse)
      allow(JSON).to receive(:parse) do |arg|
        arg == '{"data": "value"}' ? raise(JSON::ParserError.new('test')) : original_parse.call(arg)
      end
      dudes = Dude::StatusLine::Dudes.new('{"data": "value"}', [], '/tmp', 50)
      expect(dudes.to_s).to eq('')
    end

    it 'handles invalid JSON strings gracefully' do
      invalid_json = '{invalid json'
      dudes = Dude::StatusLine::Dudes.new(invalid_json, [], '/tmp', 50)
      expect(dudes.to_s).to eq('')
    end
  end
end
