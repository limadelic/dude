require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Dudes do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:sut) { described_class.new(session_data, dudes_data, dude_dir, context_pct) }
  let(:session_data) { session }
  let(:dudes_data) { default_dudes }
  let(:dude_dir) { '/tmp' }
  let(:context_pct) { 25 }

  def make_dude(name:, icon:, messages:, context:, is_current:, is_abiding:)
    dude = Object.new
    stub(dude).name { name }
    stub(dude).icon { icon }
    stub(dude).messages { messages }
    stub(dude).context { context }
    stub(dude).is_current? { is_current }
    stub(dude).is_abiding? { is_abiding }
    dude
  end

  def strip(s)
    s.gsub(/\e\[[0-9;]*m/, '')
  end

  let(:default_dudes) do
    [
      make_dude(name: 'dude', icon: '🎳', messages: 0, context: 25, is_current: true, is_abiding: true),
      make_dude(name: 'rec', icon: '🔴', messages: 3, context: 50, is_current: false, is_abiding: true),
      make_dude(name: 'smith', icon: '🤖', messages: 0, context: 80, is_current: false, is_abiding: true)
    ]
  end

  describe '#to_s' do
    it 'shows dude icons' do
      output = sut.to_s
      expect(output).to include('🎳', '🔴', '🤖')
    end

    it 'shows message count superscript' do
      output = sut.to_s
      expect(output).to match(/🔴 ?³/)
    end

    it 'shows zero superscript' do
      output = sut.to_s
      expect(output).to match(/🎳 ?⁰/)
    end

    it 'highlights current dude with background' do
      output = sut.to_s
      expect(output).to include("\e[42m\e[97m🎳")
    end

    it 'does not highlight non-current dude' do
      output = sut.to_s
      expect(output).not_to include("\e[42m\e[97m🔴")
    end

    it 'highlights current yellow dude with black text' do
      yellow_dude = make_dude(name: 'dude', icon: '🎳', messages: 0, context: 50, is_current: true, is_abiding: true)
      sut = described_class.new(session_data, [yellow_dude], dude_dir, 50)

      output = sut.to_s
      expect(output).to include("\e[48;5;226m\e[30m🎳")
    end
  end

  describe '#to_s - abide watcher status' do
    context 'not abiding' do
      it 'shows ˣ with context color' do
        dude = make_dude(name: 'rec', icon: '🔴', messages: 3, context: 50, is_current: false, is_abiding: false)
        sut = described_class.new(session_data, [dude], dude_dir, context_pct)

        output = sut.to_s
        expect(output).to include("\e[38;5;226m🔴", "ˣ")
      end

      it 'shows green ˣ with low context' do
        dude = make_dude(name: 'rec', icon: '🔴', messages: 0, context: 10, is_current: false, is_abiding: false)
        sut = described_class.new(session_data, [dude], dude_dir, context_pct)

        output = sut.to_s
        expect(output).to include("\e[32m🔴", "ˣ")
      end

      it 'has background highlight for current not-abiding dude' do
        dude = make_dude(name: 'rec', icon: '🔴', messages: 0, context: 25, is_current: true, is_abiding: false)
        sut = described_class.new(session_data, [dude], dude_dir, context_pct)

        output = sut.to_s
        expect(output).to include("\e[42m\e[97m🔴", "ˣ")
      end

      it 'shows red ˣ with high context' do
        dude = make_dude(name: 'rec', icon: '🔴', messages: 0, context: 80, is_current: false, is_abiding: false)
        sut = described_class.new(session_data, [dude], dude_dir, context_pct)

        output = sut.to_s
        expect(output).to include("\e[31m🔴", "ˣ")
      end
    end

    context 'abiding' do
      it 'shows message count' do
        dude = make_dude(name: 'rec', icon: '🔴', messages: 3, context: 50, is_current: false, is_abiding: true)
        sut = described_class.new(session_data, [dude], dude_dir, context_pct)

        output = sut.to_s
        expect(output).to match(/🔴 ?³/)
      end
    end
  end

  describe '#write_status' do
    let(:status_file) { '/tmp/status.json' }

    before do
      stub(Dir).exist?(dude_dir) { true }
      stub(JSON).load_file(status_file) { {} }
    end

    context 'context color' do
      it 'writes green at 0%' do
        mock(File).write(status_file, /green/)
        dudes = described_class.new(session_data, [], dude_dir, 0)
        dudes.write_status
      end

      it 'writes green at 32%' do
        mock(File).write(status_file, /green/)
        dudes = described_class.new(session_data, [], dude_dir, 32)
        dudes.write_status
      end

      it 'writes yellow at 33%' do
        mock(File).write(status_file, /yellow/)
        dudes = described_class.new(session_data, [], dude_dir, 33)
        dudes.write_status
      end

      it 'writes yellow at 66%' do
        mock(File).write(status_file, /yellow/)
        dudes = described_class.new(session_data, [], dude_dir, 66)
        dudes.write_status
      end

      it 'writes red at 67%' do
        mock(File).write(status_file, /red/)
        dudes = described_class.new(session_data, [], dude_dir, 67)
        dudes.write_status
      end

      it 'writes red at 100%' do
        mock(File).write(status_file, /red/)
        dudes = described_class.new(session_data, [], dude_dir, 100)
        dudes.write_status
      end
    end
  end

  describe 'initialization' do
    it 'recovers from invalid JSON in session_data' do
      invalid_session = '{"data": "value"}'
      stub(JSON).parse(invalid_session) \
        { raise JSON::ParserError.new('test') }

      sut = described_class.new(invalid_session, [], dude_dir, context_pct)
      expect(sut.to_s).to eq('')
    end

    it 'handles invalid JSON strings gracefully' do
      invalid_json = '{invalid json'
      sut = described_class.new(invalid_json, [], dude_dir, context_pct)
      expect(sut.to_s).to eq('')
    end
  end
end
