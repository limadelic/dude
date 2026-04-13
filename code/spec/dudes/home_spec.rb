require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/home'

describe Dude::Dudes::Home do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:inbox) { Object.new }
  let(:dudes_dir) { '/root/.claude/dudes' }

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
    let(:path_resolver) { Object.new }
    let(:target) { '/root/.claude' }
    let(:link_path) { "#{dudes_dir}/dude" }
    let(:resolved_target) { target }
    let(:dude_name) { 'dude' }

    before do
      stub(Dude::Dudes::PathResolver).new { path_resolver }
      stub(File).symlink?(link_path) { true }
      stub(Dude::Dudes::Dudes).pids { { 12345 => target } }
    end

    it 'resolves absolute symlink' do
      stub(File).readlink(link_path) { '/root/.claude/' }
      stub(path_resolver).expand_target('/root/.claude/', dudes_dir) { resolved_target }

      expect(sut.read_dude_link(dudes_dir, dude_name)).to eq(target)
    end

    it 'returns nil when not accessible' do
      link_path_x = "#{dudes_dir}/x"
      stub(File).symlink?(link_path_x) { true }
      stub(File).readlink(link_path_x) { '/unknown/' }
      stub(path_resolver).expand_target('/unknown/', dudes_dir) { '/unknown' }

      expect(sut.read_dude_link(dudes_dir, 'x')).to be_nil
    end
  end

  describe '#read_dude_data' do
    let(:claude_path) { '/proj/.claude/CLAUDE.md' }
    let(:status_path) { '/proj/.claude/dudes/status.json' }
    let(:dude_dir) { '/proj/.claude' }

    before do
      stub(Dude::Dudes::Inbox).new { inbox }
    end

    it 'returns data hash with icon, inbox and status' do
      stub(File).exist?(claude_path) { true }
      stub(File).read(claude_path) { "---\nicon: 🔴\n---\n" }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { '{}' }

      result = sut.read_dude_data(dude_dir)

      expect(result[:icon]).to eq('🔴')
      expect(result[:inbox]).to be(inbox)
      expect(result[:status]).to eq({})
    end

    it 'returns nil without icon' do
      stub(File).exist?(claude_path) { false }

      expect(sut.read_dude_data(dude_dir)).to be_nil
    end
  end
end
