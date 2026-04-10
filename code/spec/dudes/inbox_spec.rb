require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/inbox'

describe Dude::Dudes::Inbox do
  include RR::DSL

  let(:sut) { described_class.new(path) }
  let(:path) { '/root/.claude/dudes/inbox.json' }

  before do
    stub(File).exist?(path) { true }
    stub(JSON).load_file(path) { [] }
  end

  describe '#append' do
    it 'persists message to file' do
      mock(File).write(path, /hi/) { nil }

      sut.append({ 'text' => 'hi' })
    end

    it 'appends to existing messages' do
      stub(JSON).load_file(path) { [{ 'text' => 'old', 'status' => 'new' }] }
      mock(File).write(path, /old.*hi/) { nil }

      sut.append({ 'text' => 'hi' })
    end
  end

  describe '#mark_wip' do
    it 'updates first item status to wip' do
      stub(JSON).load_file(path) { [{ 'text' => 'hi', 'status' => 'new' }] }
      mock(File).write(path, /wip/) { nil }

      sut.mark_wip
    end

    it 'skips empty inbox' do
      dont_allow(File).write

      sut.mark_wip
    end
  end

  describe '#dequeue_wip' do
    it 'removes first item when wip' do
      stub(JSON).load_file(path) do
        [
          { 'text' => 'hi', 'status' => 'wip' },
          { 'text' => 'bye', 'status' => 'new' }
        ]
      end
      mock(File).write(path, /bye/) { nil }

      sut.dequeue_wip
    end

    it 'skips removal when not wip' do
      stub(JSON).load_file(path) { [{ 'text' => 'hi', 'status' => 'new' }] }
      dont_allow(File).write

      sut.dequeue_wip
    end
  end

  describe '#first_new' do
    it 'returns first new message' do
      stub(JSON).load_file(path) do
        [{ 'text' => 'hi', 'status' => 'new' }]
      end

      expect(sut.first_new)
        .to eq({ 'text' => 'hi', 'status' => 'new' })
    end

    it 'returns nil when no new messages' do
      stub(JSON).load_file(path) { [{ 'text' => 'hi', 'status' => 'wip' }] }

      expect(sut.first_new).to be_nil
    end

    it 'returns nil when inbox missing' do
      stub(File).exist?(path) { false }

      expect(sut.first_new).to be_nil
    end
  end
end
