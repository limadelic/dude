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
      stub(FileUtils).mkdir_p
      stub(File).write
      stub(File).symlink
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

    before do
      stub(Dir).children { [] }
      stub(File).symlink? { false }
      stub(File).readlink
      stub(FileUtils).rm_rf
      stub(File).delete
    end

    it 'checks global dudes directory' do
      mock(Dir).exist?.with(anything) { true }
      stub(Dir).children { [] }

      sut.unpub(unpub_target)
    end

    it 'exits early when global dir missing' do
      mock(Dir).exist?.with(anything) { false }

      sut.unpub(unpub_target)
    end

    it 'removes symlink targets' do
      stub(Dir).exist? { true }
      stub(Dir).children { ['rec', 'smith'] }
      stub(File).symlink? { true }
      stub(File).readlink { '/proj/.claude/' }
      mock(FileUtils).rm_rf.times(2)
      mock(File).delete.times(2)

      sut.unpub(unpub_target)
    end
  end

  describe '#sub' do
    let(:sub_target) { '/code' }
    let(:sub_name) { 'dev' }
    let(:parent_pub) { { name: 'dude', path: '/home/.claude/dudes' } }

    before do
      stub(Dude::Dudes::PubFinder).find_nearest_pub { parent_pub }
      stub(FileUtils).mkdir_p
      stub(File).write
      stub(File).symlink
    end

    it 'returns underscore-prefixed name' do
      result = sut.sub(sub_target, sub_name)

      expect(result).to eq('dude_dev')
    end

    it 'uses target basename as default name' do
      result = sut.sub('/some/path/code', nil)

      expect(result).to eq('dude_code')
    end

    it 'finds parent pub' do
      mock(Dude::Dudes::PubFinder).find_nearest_pub { parent_pub }

      sut.sub(sub_target, sub_name)
    end
  end
end
