require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Dudes do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:sut) {
    described_class.new(session_data, dudes_data, dude_dir, context_pct)
  }
  let(:session_data) { session }
  let(:dudes_data) { default_dudes }
  let(:dude_dir) { '/tmp' }
  let(:context_pct) { 25 }

  def make_dude(name:, icon:, messages:, context:, is_current:, is_abiding:)
    dude = Object.new
    [
      [:name, name], [:icon, icon], [:messages, messages],
      [:context, context], [:is_current?, is_current],
      [:is_abiding?, is_abiding]
    ].each do |method, value|
      stub(dude).__send__(method) { value }
    end
    dude
  end

  def strip(s)
    s.gsub(/\e\[[0-9;]*m/, '')
  end

  let(:default_dudes) do
    [
      make_dude(
        name: 'dude', icon: '🎳', messages: 0, context: 25,
        is_current: true, is_abiding: true
      ),
      make_dude(
        name: 'rec', icon: '🔴', messages: 3, context: 50,
        is_current: false, is_abiding: true
      ),
      make_dude(
        name: 'smith', icon: '🤖', messages: 0, context: 80,
        is_current: false, is_abiding: true
      )
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

    context 'yellow dude at context 50' do
      let(:dudes_data) do
        [
          make_dude(
            name: 'dude', icon: '🎳', messages: 0, context: 50,
            is_current: true, is_abiding: true
          )
        ]
      end
      let(:context_pct) { 50 }

      it 'highlights current yellow dude with black text' do
        output = sut.to_s
        expect(output).to include("\e[48;5;226m\e[30m🎳")
      end
    end
  end

  describe '#to_s - abide watcher status' do
    context 'not abiding' do
      let(:dudes_data) do
        [
          make_dude(
            name: 'rec', icon: '🔴', messages: 3, context: 50,
            is_current: false, is_abiding: false
          )
        ]
      end

      context 'at context 50' do
        let(:context_pct) { 50 }

        it 'shows ˣ with context color' do
          output = sut.to_s
          expect(output).to include("\e[38;5;226m🔴", "ˣ")
        end
      end

      context 'at low context 10' do
        let(:dudes_data) do
          [
            make_dude(
              name: 'rec', icon: '🔴', messages: 0, context: 10,
              is_current: false, is_abiding: false
            )
          ]
        end

        it 'shows green ˣ with low context' do
          output = sut.to_s
          expect(output).to include("\e[32m🔴", "ˣ")
        end
      end

      context 'current not-abiding dude at context 25' do
        let(:dudes_data) do
          [
            make_dude(
              name: 'rec', icon: '🔴', messages: 0, context: 25,
              is_current: true, is_abiding: false
            )
          ]
        end

        it 'has background highlight' do
          output = sut.to_s
          expect(output).to include("\e[42m\e[97m🔴", "ˣ")
        end
      end

      context 'at high context 80' do
        let(:dudes_data) do
          [
            make_dude(
              name: 'rec', icon: '🔴', messages: 0, context: 80,
              is_current: false, is_abiding: false
            )
          ]
        end

        it 'shows red ˣ with high context' do
          output = sut.to_s
          expect(output).to include("\e[31m🔴", "ˣ")
        end
      end
    end

    context 'abiding' do
      let(:dudes_data) do
        [
          make_dude(
            name: 'rec', icon: '🔴', messages: 3, context: 50,
            is_current: false, is_abiding: true
          )
        ]
      end

      it 'shows message count' do
        output = sut.to_s
        expect(output).to match(/🔴 ?³/)
      end
    end
  end

  describe '#write_status' do
    let(:status_file) { '/tmp/status.json' }
    let(:dudes_data) { [] }

    before do
      stub(Dir).exist?(dude_dir) { true }
      stub(JSON).load_file(status_file) { {} }
    end

    context 'context color' do
      context 'at 0%' do
        let(:context_pct) { 0 }

        it 'writes green' do
          mock(File).write(status_file, /green/)
          sut.write_status
        end
      end

      context 'at 32%' do
        let(:context_pct) { 32 }

        it 'writes green' do
          mock(File).write(status_file, /green/)
          sut.write_status
        end
      end

      context 'at 33%' do
        let(:context_pct) { 33 }

        it 'writes yellow' do
          mock(File).write(status_file, /yellow/)
          sut.write_status
        end
      end

      context 'at 66%' do
        let(:context_pct) { 66 }

        it 'writes yellow' do
          mock(File).write(status_file, /yellow/)
          sut.write_status
        end
      end

      context 'at 67%' do
        let(:context_pct) { 67 }

        it 'writes red' do
          mock(File).write(status_file, /red/)
          sut.write_status
        end
      end

      context 'at 100%' do
        let(:context_pct) { 100 }

        it 'writes red' do
          mock(File).write(status_file, /red/)
          sut.write_status
        end
      end
    end
  end

  describe 'initialization' do
    context 'with invalid JSON in session_data' do
      let(:invalid_session) { '{"data": "value"}' }
      let(:session_data) { invalid_session }
      let(:dudes_data) { [] }

      before do
        stub(JSON).parse(invalid_session) \
          { raise JSON::ParserError.new('test') }
      end

      it 'recovers and returns empty string' do
        expect(sut.to_s).to eq('')
      end
    end

    context 'with malformed JSON string' do
      let(:session_data) { '{invalid json' }
      let(:dudes_data) { [] }

      it 'handles gracefully and returns empty string' do
        expect(sut.to_s).to eq('')
      end
    end
  end
end
