require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/home'

describe Dude::Dudes::Home do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:path_resolver) { Object.new }
  let(:inbox) { Object.new }
  let(:dudes_dir) { '/root/.claude/dudes' }
  let(:target) { '/root/.claude' }

  before { stub(Dude::Dudes::PathResolver).new { path_resolver } }

  describe '#list_dude_names' do
    it 'returns symlinked children' do
      stub(Dir).children(dudes_dir) { %w[rec tmp] }
      stub(File).symlink?("#{dudes_dir}/rec") { true }
      stub(File).symlink?("#{dudes_dir}/tmp") { false }

      expect(sut.list_dude_names(dudes_dir)).to eq(%w[rec])
    end

    it 'returns empty on error' do
      stub(Dir).children(dudes_dir) { raise Errno::ENOENT }

      expect(sut.list_dude_names(dudes_dir)).to eq([])
    end
  end

  describe '#read_dude_link' do
    it 'resolves absolute symlink' do
      link_path = "#{dudes_dir}/dude"
      stub(File).symlink?(link_path) { true }
      stub(File).readlink(link_path) { '/root/.claude/' }
      stub(path_resolver).expand_target('/root/.claude/', dudes_dir) { target }
      stub(Dude::Dudes::Dudes).pids { { 12345 => target } }

      expect(sut.read_dude_link(dudes_dir, 'dude')).to eq(target)
    end

    it 'returns nil when not accessible' do
      link_path = "#{dudes_dir}/x"
      stub(File).symlink?(link_path) { true }
      stub(File).readlink(link_path) { '/unknown/' }
      stub(path_resolver).expand_target('/unknown/', dudes_dir) { '/unknown' }
      stub(Dude::Dudes::Dudes).pids { { 12345 => '/root/.claude' } }

      expect(sut.read_dude_link(dudes_dir, 'x')).to be_nil
    end
  end

  describe '#read_dude_data' do
    it 'returns data hash with icon and inbox with path' do
      claude_path = '/proj/.claude/CLAUDE.md'
      stub(File).exist?(claude_path) { true }
      stub(File).read(claude_path) { "---\nicon: 🔴\n---\n" }
      stub(Dude::Dudes::Inbox).new { inbox }
      stub(File).exist?(/status\.json/) { true }
      stub(File).read(/status\.json/) { '{}' }

      result = sut.read_dude_data('/proj/.claude')

      expect(result[:icon]).to eq('🔴')
      expect(result[:inbox]).to be(inbox)
    end

    it 'returns nil without icon' do
      claude_path = '/proj/.claude/CLAUDE.md'
      stub(File).exist?(claude_path) { false }

      expect(sut.read_dude_data('/proj/.claude')).to be_nil
    end
  end
end
