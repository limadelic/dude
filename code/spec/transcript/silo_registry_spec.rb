require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/silo_registry'

describe Dude::Transcript::SiloRegistry do
  include RR::DSL
  let(:sut) { described_class.new(registry_path) }

  let(:registry_path) { '/home/user/.claude/silos.json' }
  let(:silos_data) do
    {
      'silos' => {
        'dude' => {
          'id' => 'uuid-dude',
          'dom' => 'dude',
          'home' => '/Users/mike/dude',
          'color' => 'orange',
          'emoji' => '🤠'
        },
        'code' => {
          'id' => 'uuid-code',
          'dom' => 'dude',
          'home' => '/Users/mike/dude/silos/code',
          'color' => 'blue'
        },
        'dude.kent' => {
          'id' => 'uuid-kent',
          'dom' => 'dude',
          'home' => '/Users/mike/dude/silos/kent',
          'color' => 'green',
          'emoji' => '🏅'
        }
      }
    }
  end

  describe '#load' do
    context 'when registry file exists with valid JSON' do
      before do
        stub(File).exist?(registry_path) { true }
        stub(JSON).load_file(registry_path) { silos_data }
      end

      it 'loads registry from file' do
        sut.load

        roster = sut.roster
        expect(roster).to have_key('dude')
        expect(roster).to have_key('code')
        expect(roster).to have_key('dude.kent')
      end

      it 'provides silo id by name' do
        sut.load

        expect(sut.silo_id('dude')).to eq('uuid-dude')
        expect(sut.silo_id('code')).to eq('uuid-code')
      end
    end

    context 'when registry file does not exist' do
      before do
        stub(File).exist?(registry_path) { false }
      end

      it 'returns empty roster' do
        sut.load

        expect(sut.roster).to eq({})
      end
    end

    context 'when JSON is invalid' do
      before do
        stub(File).exist?(registry_path) { true }
        stub(JSON).load_file(registry_path) { raise JSON::ParserError.new('bad json') }
      end

      it 'returns empty roster on parse error' do
        sut.load

        expect(sut.roster).to eq({})
      end
    end

    context 'when file raises unexpected error' do
      before do
        stub(File).exist?(registry_path) { true }
        err = StandardError.new('unexpected')
        stub(JSON).load_file(registry_path) { raise err }
      end

      it 'returns empty roster on error' do
        sut.load

        expect(sut.roster).to eq({})
      end
    end
  end

  describe '#silo_id' do
    before { stub(File).exist?(registry_path) { true } }

    context 'with loaded registry' do
      before do
        stub(JSON).load_file(registry_path) { silos_data }
        sut.load
      end

      it 'returns silo id for known name' do
        expect(sut.silo_id('dude')).to eq('uuid-dude')
      end

      it 'returns nil for unknown name' do
        expect(sut.silo_id('unknown')).to be_nil
      end
    end

    context 'with empty registry' do
      before do
        stub(JSON).load_file(registry_path) { { 'silos' => {} } }
        sut.load
      end

      it 'returns nil for any name' do
        expect(sut.silo_id('dude')).to be_nil
      end
    end
  end

  describe '#emoji' do
    before { stub(File).exist?(registry_path) { true } }

    context 'with loaded registry' do
      before do
        stub(JSON).load_file(registry_path) { silos_data }
        sut.load
      end

      it 'returns emoji for silo with emoji field' do
        expect(sut.emoji('dude')).to eq('🤠')
      end

      it 'returns nil when emoji field is absent' do
        expect(sut.emoji('code')).to be_nil
      end

      it 'returns nil for unknown name' do
        expect(sut.emoji('unknown')).to be_nil
      end
    end

    context 'with empty registry' do
      before do
        stub(JSON).load_file(registry_path) { { 'silos' => {} } }
        sut.load
      end

      it 'returns nil for any name' do
        expect(sut.emoji('dude')).to be_nil
      end
    end
  end

  describe '#roster' do
    context 'before load is called' do
      before do
        stub(File).exist?(registry_path) { false }
      end

      it 'returns empty roster' do
        expect(sut.roster).to eq({})
      end
    end

    context 'after load is called' do
      before do
        stub(File).exist?(registry_path) { true }
        stub(JSON).load_file(registry_path) { silos_data }
        sut.load
      end

      it 'returns all silo names from registry' do
        roster = sut.roster
        expect(roster.keys).to contain_exactly('dude', 'code', 'dude.kent')
      end

      it 'returns silo data for each name' do
        roster = sut.roster
        expect(roster['dude']['id']).to eq('uuid-dude')
        expect(roster['code']['home']).to eq('/Users/mike/dude/silos/code')
      end
    end
  end

  describe 'with custom path' do
    let(:custom_path) { '/custom/path/silos.json' }
    let(:sut) { described_class.new(custom_path) }

    before do
      stub(File).exist?(custom_path) { true }
      stub(JSON).load_file(custom_path) { silos_data }
    end

    it 'uses injected path instead of default' do
      sut.load

      expect(sut.roster).to have_key('dude')
    end
  end

  describe 'loading real JSON file' do
    let(:temp_file) { "/tmp/silos_#{$$}_#{Time.now.to_i}.json" }
    let(:sut) { described_class.new(temp_file) }

    before do
      File.write(temp_file, JSON.generate(silos_data))
    end

    after do
      File.delete(temp_file) if File.exist?(temp_file)
    end

    it 'loads actual JSON file without mocking' do
      sut.load

      expect(sut.roster).to have_key('dude')
      expect(sut.silo_id('code')).to eq('uuid-code')
    end
  end
end
