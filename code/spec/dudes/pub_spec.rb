require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/pub'

describe Dude::Dudes::Pub do
  include RR::DSL

  let(:sut) { described_class.new(target: target) }
  let(:target) { '/proj/.claude' }

  describe '#pub' do
    let(:icon) { 'myicon' }
    let(:pub_target) { '/proj/.claude' }

    before do
      stub(File).exist? { false }
      stub(File).symlink? { false }
      stub(JSON).load_file { {} }
      stub(FileUtils).mkdir_p
      stub(File).write
      stub(File).symlink
      stub(File).delete
    end

    it 'returns provided icon' do
      result = sut.pub(pub_target, icon)

      expect(result).to eq(icon)
    end

    it 'uses target as default icon' do
      result = sut.pub(pub_target, nil)

      expect(result).to eq(pub_target)
    end
  end

  describe '#unpub' do
    let(:unpub_target) { '/proj/.claude' }

    it 'checks global dudes directory' do
      mock(Dir).exist?.with(/dudes/) { true }
      stub(Dir).children { [] }
      stub(File).symlink? { false }
      stub(File).readlink
      stub(FileUtils).rm_rf
      stub(File).delete

      sut.unpub(unpub_target)
    end

    it 'exits early when global dir missing' do
      mock(Dir).exist?.with(/dudes/) { false }

      sut.unpub(unpub_target)
    end

    it 'removes symlink targets' do
      stub(Dir).exist? { true }
      stub(Dir).children { ['rec', 'smith'] }
      stub(File).symlink? { true }
      stub(File).readlink { '/proj/.claude/' }
      mock(FileUtils).rm_rf.with(/dudes/).times(2) { nil }
      mock(File).delete.with(/dudes/).times(2) { nil }

      sut.unpub(unpub_target)
    end
  end

  describe '#sub' do
    let(:sub_target) { '/code' }
    let(:sub_name) { 'dev' }
    let(:parent_pub) { { name: 'dude', path: '/home/.claude/dudes' } }

    before do
      stub(File).exist? { false }
      stub(JSON).load_file { {} }
      stub(File).symlink? { false }
      stub(Dir).exist? { false }
      stub(FileUtils).mkdir_p
      stub(File).write
      stub(File).symlink
      stub(File).delete
    end

    it 'returns underscore-prefixed name' do
      stub(Dude::Dudes::PubFinder).find_nearest_pub { parent_pub }

      result = sut.sub(sub_target, sub_name)

      expect(result).to eq('dude_dev')
    end

    it 'uses target basename as default name' do
      stub(Dude::Dudes::PubFinder).find_nearest_pub { parent_pub }

      result = sut.sub('/some/path/code', nil)

      expect(result).to eq('dude_code')
    end

    it 'finds parent pub' do
      mock(Dude::Dudes::PubFinder).find_nearest_pub.with(/code/) { parent_pub }

      sut.sub(sub_target, sub_name)
    end
  end

  describe '#claude_dir' do
    it 'returns path when it is .claude' do
      result = sut.send(:claude_dir, '/home/user/.claude')

      expect(result).to eq('/home/user/.claude')
    end

    it 'returns .claude when it exists' do
      stub(Dir).exist? { |path| path == '/projects/myapp/.claude' }

      result = sut.send(:claude_dir, '/projects/myapp')

      expect(result).to eq('/projects/myapp/.claude')
    end

    it 'returns path when .claude does not exist' do
      stub(Dir).exist? { false }

      result = sut.send(:claude_dir, '/some/path')

      expect(result).to eq('/some/path')
    end

    it 'avoids .claude/.claude' do
      stub(Dir).exist? { true }

      result = sut.send(:claude_dir, '/home/user/.claude')

      expect(result).to eq('/home/user/.claude')
    end
  end
end
