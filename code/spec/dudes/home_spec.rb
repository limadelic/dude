require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/home'

describe Dude::Dudes::Home do
  let(:home) { described_class.new }
  let(:dir) { '/root/.claude/dudes' }

  before do
    allow(File).to receive(:symlink?).and_return(true)
    allow(Dude::Dudes::Dudes).to receive(:pids).and_return(
      { 12345 => '/root/.claude' }
    )
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:read).and_return('')
  end

  describe '#list_dude_names' do
    it 'returns symlinked children' do
      allow(Dir).to receive(:children).and_return(%w[rec tmp])
      allow(File).to receive(:symlink?).with("#{dir}/tmp").and_return(false)
      expect(home.list_dude_names(dir)).to eq(%w[rec])
    end

    it 'returns empty on error' do
      allow(Dir).to receive(:children).and_raise(Errno::ENOENT)
      expect(home.list_dude_names(dir)).to eq([])
    end
  end

  describe '#read_dude_link' do
    it 'resolves absolute symlink' do
      allow(File).to receive(:readlink).and_return('/root/.claude/')
      expect(home.read_dude_link(dir, 'dude')).to eq('/root/.claude')
    end

    it 'returns nil when not accessible' do
      allow(File).to receive(:readlink).and_return('/unknown/')
      expect(home.read_dude_link(dir, 'x')).to be_nil
    end
  end

  describe '#read_dude_data' do
    it 'returns data hash with icon and inbox with path' do
      allow(File).to receive(:read).and_return("---\nicon: 🔴\n---\n")
      allow(JSON).to receive(:load_file).and_return({ 'context' => 50 })
      result = home.read_dude_data('/proj/.claude')
      expect(result[:icon]).to eq('🔴')
      expect(result[:inbox]).to be_a(Dude::Dudes::Inbox)
    end

    it 'returns nil without icon' do
      allow(File).to receive(:exist?).and_return(false)
      expect(home.read_dude_data('/proj/.claude')).to be_nil
    end
  end
end
