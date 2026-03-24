require_relative '../spec_helper'
require_relative '../../lib/dudes/home'

describe Dudes::Home do
  let(:fs) { instance_double(Helpers::FS) }
  let(:home) { described_class.new(fs) }
  let(:dir) { '/root/.claude/dudes' }

  before do
    allow(fs).to receive(:symlink?).and_return(true)
    allow(fs).to receive(:claude_cwds).and_return(['/root/.claude'])
    allow(fs).to receive(:exist?).and_return(true)
    allow(fs).to receive(:read).and_return('')
  end

  describe '#list_dude_names' do
    it 'returns symlinked children' do
      allow(fs).to receive(:children).and_return(%w[rec tmp])
      allow(fs).to receive(:symlink?).with("#{dir}/tmp").and_return(false)
      expect(home.list_dude_names(dir)).to eq(%w[rec])
    end

    it 'returns empty on error' do
      allow(fs).to receive(:children).and_raise(Errno::ENOENT)
      expect(home.list_dude_names(dir)).to eq([])
    end
  end

  describe '#read_dude_link' do
    it 'resolves absolute symlink' do
      allow(fs).to receive(:readlink).and_return('/root/.claude/')
      expect(home.read_dude_link(dir, 'dude')).to eq('/root/.claude')
    end

    it 'returns nil when not accessible' do
      allow(fs).to receive(:readlink).and_return('/unknown/')
      expect(home.read_dude_link(dir, 'x')).to be_nil
    end
  end

  describe '#read_dude_data' do
    it 'returns data hash with icon' do
      allow(fs).to receive(:read).and_return("---\nicon: 🔴\n---\n", '{"context":50}', '[{}]')
      result = home.read_dude_data('/proj/.claude')
      expect(result[:icon]).to eq('🔴')
      expect(result[:inbox]).to eq([{}])
    end

    it 'returns nil without icon' do
      allow(fs).to receive(:exist?).and_return(false)
      expect(home.read_dude_data('/proj/.claude')).to be_nil
    end
  end
end
