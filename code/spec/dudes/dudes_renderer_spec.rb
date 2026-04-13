require_relative '../spec_helper'
require_relative "../../lib/dude/status_line/dudes"
require_relative "../examples/shared"

describe Dude::StatusLine::Dudes do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:sut) { described_class.new(session_json, dudes_list, '/tmp', context_pct) }
  let(:session_json) { '' }
  let(:dudes_list) { nil }
  let(:context_pct) { 0 }

  before do
    stub_const('Dude::StatusLine::Format::JETBRAINS', false)
    stub(Dir).exist? { |path| true if path == '/tmp' }
    stub(JSON).load_file(anything) { {} }
  end

  def build_dude(name:, icon:, messages:, context:, current:, abiding: true)
    d = Object.new
    stub(d).name { name }
    stub(d).icon { icon }
    stub(d).messages { messages }
    stub(d).context { context }
    stub(d).is_current? { current }
    stub(d).is_abiding? { abiding }
    d
  end

  describe 'Dudes section' do
    let(:dudes_list) do
      [
        build_dude(name: 'dude', icon: '🎳', messages: 0, context: 25, current: true),
        build_dude(name: 'rec', icon: '🔴', messages: 3, context: 50, current: false),
        build_dude(name: 'smith', icon: '🤖', messages: 0, context: 80, current: false)
      ]
    end
    let(:session_json) { mock_session('opus', 25).to_json }

    it 'shows dude icons' do
      result = sut.to_s
      stripped = Dude::StatusLine::Format.strip(result)

      expect(stripped).to include('🎳', '🔴', '🤖')
    end

    it 'shows message count superscript' do
      result = sut.to_s
      stripped = Dude::StatusLine::Format.strip(result)

      expect(stripped).to match(/🔴³/)
    end

    it 'shows zero superscript' do
      result = sut.to_s
      stripped = Dude::StatusLine::Format.strip(result)

      expect(stripped).to match(/🎳⁰/)
    end

    it 'highlights current dude with background' do
      result = sut.to_s

      expect(result).to include("\e[42m\e[97m🎳")
    end

    it 'does not highlight non-current dude' do
      result = sut.to_s

      expect(result).not_to include("\e[42m\e[97m🔴")
    end

    context 'yellow dude' do
      let(:yellow_dude) do
        build_dude(
          name: 'dude', icon: '🎳', messages: 0, context: 50, current: true
        )
      end
      let(:session_data) do
        { 'model' => { 'id' => 'claude-opus-4-6' },
          'context_window' => { 'used_percentage' => 50 } }.to_json
      end
      let(:sut) { described_class.new(session_data, [yellow_dude], '/tmp', 50) }

      it 'highlights with black text' do
        result = sut.to_s

        expect(result).to include("\e[48;5;226m\e[30m🎳")
      end
    end
  end

  describe 'Abide watcher status' do
    context 'not abiding' do
      let(:rec) do
        build_dude(
          name: 'rec', icon: '🔴', messages: 0, context: 50, current: false, abiding: false
        )
      end
      let(:sut) { described_class.new('', [rec], '/tmp', 0) }

      context 'with messages' do
        let(:rec) do
          build_dude(
            name: 'rec', icon: '🔴', messages: 3, context: 50, current: false, abiding: false
          )
        end

        it 'shows ˣ with context color' do
          result = sut.to_s
          expect(result).to include("\e[38;5;226m🔴", "ˣ")
        end
      end

      context 'with low context' do
        let(:rec) do
          build_dude(
            name: 'rec', icon: '🔴', messages: 0, context: 10, current: false, abiding: false
          )
        end

        it 'shows green ˣ with low context' do
          result = sut.to_s
          expect(result).to include("\e[32m🔴", "ˣ")
        end
      end

      context 'current' do
        let(:rec) do
          build_dude(
            name: 'rec', icon: '🔴', messages: 0, context: 25, current: true, abiding: false
          )
        end

        it 'has background highlight for current not-abiding dude' do
          result = sut.to_s
          expect(result).to include("\e[42m\e[97m🔴", "ˣ")
        end
      end

      context 'with high context' do
        let(:rec) do
          build_dude(
            name: 'rec', icon: '🔴', messages: 0, context: 80, current: false, abiding: false
          )
        end

        it 'shows red ˣ with high context' do
          result = sut.to_s
          expect(result).to include("\e[31m🔴", "ˣ")
        end
      end
    end

    context 'abiding' do
      let(:rec) do
        build_dude(
          name: 'rec', icon: '🔴', messages: 3, context: 50, current: false, abiding: true
        )
      end
      let(:sut) { described_class.new('', [rec], '/tmp', 0) }

      it 'shows message count' do
        result = sut.to_s
        stripped = Dude::StatusLine::Format.strip(result)

        expect(stripped).to match(/🔴³/)
      end
    end
  end

  describe '#write_status' do
    context 'context color' do
      {
        0 => 'green', 32 => 'green', 33 => 'yellow', 66 => 'yellow',
        67 => 'red', 100 => 'red'
      }.each do |pct, color|
        it "writes #{color} at #{pct}%" do
          sut_color = described_class.new({}, nil, '/tmp', pct)
          written = nil
          stub(File).write(anything, anything) { |_path, content| written = content }

          sut_color.write_status

          expect(written).to include("color")
          parsed = JSON.parse(written)
          expect(parsed['color']).to eq(color)
        end
      end
    end
  end
end
