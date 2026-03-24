require_relative '../spec_helper'
require_relative '../../lib/status_line'

describe Dudes::Renderer do
  include_context 'StatusLine helpers'

  let(:dudes_data) do
    [
      { name: 'dude', icon: '🎳', messages: 0, context: 25, current: true },
      { name: 'rec', icon: '🔴', messages: 3, context: 50, current: false },
      { name: 'smith', icon: '🤖', messages: 0, context: 80, current: false }
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
      yellow_dudes = [{ name: 'dude', icon: '🎳', messages: 0, context: 50, current: true }]
      session_data = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 50 } }.to_json
      output = out(session_data, activity, yellow_dudes)
      expect(output).to include("\e[48;5;226m\e[30m🎳")
    end
  end

  describe 'Abide watcher status' do
    context 'dead watcher' do
      it 'shows ˣ with context color' do
        dudes = [{ name: 'rec', icon: '🔴', messages: 3, context: 50, current: false, abide_dead: true }]
        output = out(session, activity, dudes)
        expect(output).to include("\e[38;5;226m🔴", "ˣ")
      end

      it 'shows green ˣ with low context' do
        dudes = [{ name: 'rec', icon: '🔴', messages: 0, context: 10, current: false, abide_dead: true }]
        output = out(session, activity, dudes)
        expect(output).to include("\e[32m🔴", "ˣ")
      end

      it 'has background highlight for current dead dude' do
        dudes = [{ name: 'rec', icon: '🔴', messages: 0, context: 25, current: true, abide_dead: true }]
        output = out(session, activity, dudes)
        expect(output).to include("\e[42m\e[97m🔴", "ˣ")
      end

      it 'shows red ˣ with high context' do
        dudes = [{ name: 'rec', icon: '🔴', messages: 0, context: 80, current: false, abide_dead: true }]
        output = out(session, activity, dudes)
        expect(output).to include("\e[31m🔴", "ˣ")
      end
    end

    context 'alive watcher' do
      it 'shows message count' do
        dudes = [{ name: 'rec', icon: '🔴', messages: 3, context: 50, current: false, abide_dead: false }]
        output = out(session, activity, dudes)
        expect(strip(output)).to match(/🔴 ?³/)
      end
    end

    context 'when abide_dead key absent' do
      it 'shows message count' do
        dudes = [{ name: 'rec', icon: '🔴', messages: 3, context: 50, current: false }]
        output = out(session, activity, dudes)
        expect(strip(output)).to match(/🔴 ?³/)
      end
    end
  end

  describe '#write_status' do
    let(:fs) { double('fs', dir_exist?: true, read: '{}', write: nil) }
    let(:pct) { 50 }
    let(:renderer) { Dudes::Renderer.new({}, nil, '/tmp', fs, pct) }

    before { allow(renderer).to receive(:system) }

    context 'context color' do
      { 0 => 'green', 32 => 'green', 33 => 'yellow', 66 => 'yellow', 67 => 'red', 100 => 'red' }.each do |p, c|
        it "writes #{c} at #{p}%" do
          r = Dudes::Renderer.new({}, nil, '/tmp', fs, p)
          allow(r).to receive(:system)
          r.write_status
          expect(fs).to have_received(:write).with(anything, include("\"color\":\"#{c}\""))
        end
      end
    end

    context 'session color sync' do
      it 'fires when color changes' do
        allow(fs).to receive(:read).and_return('{"color":"green"}')
        renderer.write_status
        expect(renderer).to have_received(:system)
      end

      it 'skips when color unchanged' do
        allow(fs).to receive(:read).and_return('{"color":"yellow"}')
        renderer.write_status
        expect(renderer).not_to have_received(:system)
      end

      it 'fires on first run' do
        renderer.write_status
        expect(renderer).to have_received(:system)
      end
    end
  end
end
