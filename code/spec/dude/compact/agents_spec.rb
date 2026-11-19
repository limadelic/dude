require_relative '../../spec_helper'
require_relative '../../../lib/dude/compact/agents'
require 'open3'

describe Dude::Compact::Agents do
  include RR::DSL

  let(:sut) { described_class.new(silo) }
  let(:silo) { 'frumble' }
  let(:command) { %w[claude agents --json] }
  let(:error) { Dude::Compact::Agents::Error }
  let(:frumble) { row('frumble', 'zorb-session', '/proj/frumble') }
  let(:upper) { row('Frumble', 'zorb-session', '/proj/upper') }
  let(:blorp) { row('blorp', 'quux-session', '/proj/blorp') }
  let(:fork) { row('frumble ⑂ zim', 'wibble-session', '/proj/zim') }
  let(:twin) { row('frumble', 'plonk-session', '/proj/twin') }
  let(:rows) { [blorp, frumble] }
  let(:json) { JSON.generate(rows) }
  let(:run) { [json, exit_status(true)] }

  before do
    stub(Open3).capture2(*command) { run }
  end

  def row(name, session_id, cwd)
    {
      'id' => 'flib', 'cwd' => cwd, 'kind' => 'background',
      'sessionId' => session_id, 'name' => name, 'state' => 'working'
    }
  end

  def exit_status(success)
    status = Object.new
    stub(status).success? { success }
    status
  end

  describe '#find' do
    it 'returns the session row named like the silo' do
      expect(sut.find).to eq(frumble)
    end

    context 'when a fork of the silo exists' do
      let(:rows) { [blorp, fork] }

      context 'and the silo is the fork' do
        let(:silo) { 'frumble ⑂ zim' }

        it 'returns the session row named like the fork' do
          expect(sut.find).to eq(fork)
        end
      end

      context 'and the silo is only the base' do
        it 'raises an error listing the candidate names' do
          expect { sut.find }.to raise_error(error, /frumble ⑂ zim\z/)
        end
      end
    end

    context 'when a session differs from the silo only in case' do
      let(:rows) { [blorp, upper] }

      it 'raises an error listing the candidate names' do
        expect { sut.find }.to raise_error(error, /blorp, Frumble\z/)
      end
    end

    context 'when no session has the silo name' do
      let(:silo) { 'zorb' }

      before do
        mock(Open3).capture2(*command) { run }
      end

      it 'raises an error listing the candidate names' do
        expect { sut.find }.to raise_error(error, /candidates: blorp, frumble/)
      end
    end

    context 'when two sessions have the silo name' do
      let(:rows) { [frumble, blorp, twin] }

      it 'raises an error listing both sessions' do
        expect { sut.find }.to raise_error(error, /zorb-session.*plonk-session/)
      end
    end

    context 'when claude is not installed' do
      let(:run) { raise Errno::ENOENT }

      it 'raises a compact error' do
        expect { sut.find }.to raise_error(error, /claude not found/)
      end
    end

    context 'when claude exits with a failure' do
      let(:run) { [json, exit_status(false)] }

      it 'raises a compact error' do
        expect { sut.find }.to raise_error(error, /claude agents failed/)
      end
    end

    context 'when claude prints bad JSON' do
      let(:json) { 'not json {{' }

      it 'raises a compact error' do
        expect { sut.find }.to raise_error(error, /gave bad JSON/)
      end
    end
  end
end
