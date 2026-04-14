require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/inbox'

describe Dude::Dudes::Inbox do
  include RR::DSL

  let(:sut) { described_class.new(path) }
  let(:path) { '/root/.claude/dudes/inbox.json' }
  let(:empty_data) { [] }
  let(:one_old_msg) { [{ 'text' => 'old', 'status' => 'new' }] }
  let(:one_new_msg) { [{ 'text' => 'hi', 'status' => 'new' }] }
  let(:one_wip_msg) { [{ 'text' => 'hi', 'status' => 'wip' }] }
  let(:wip_and_new) do
    [
      { 'text' => 'hi', 'status' => 'wip' },
      { 'text' => 'bye', 'status' => 'new' }
    ]
  end

  before do
    stub(File).exist?(path) { true }
    stub(JSON).load_file(path) { empty_data }
end

  describe '#append' do
    it 'persists message to file' do
      stub(File).write(path, anything) { nil }

      sut.append({ 'text' => 'hi' })
      expect(sut.length).to eq(1)
    end

    it 'appends to existing messages' do
      stub(JSON).load_file(path) { one_old_msg }
      stub(File).write(path, anything) { nil }

      sut.append({ 'text' => 'hi' })
      expect(sut.length).to eq(2)
    end
  end

  describe '#mark_wip' do
    it 'updates first item status to wip' do
      stub(JSON).load_file(path) { one_new_msg }
      stub(File).write(path, anything) { nil }

      sut.mark_wip
      expect(sut.first_new).to be_nil
    end

    context 'when inbox is empty' do
      before { dont_allow(File).write }

      it 'skips empty inbox' do
        sut.mark_wip
      end
    end
  end

  describe '#dequeue_wip' do
    it 'removes first item when wip' do
      stub(JSON).load_file(path) { wip_and_new }
      stub(File).write(path, anything) { nil }

      sut.dequeue_wip
      expect(sut.length).to eq(1)
    end

    context 'when message is not wip' do
      before do
        stub(JSON).load_file(path) { one_new_msg }
        dont_allow(File).write
      end

      it 'skips removal when not wip' do
        sut.dequeue_wip
      end
    end
  end

  describe '#first_new' do
    it 'returns first new message' do
      stub(JSON).load_file(path) { one_new_msg }

      expect(sut.first_new).to eq({ 'text' => 'hi', 'status' => 'new' })
    end

    it 'returns nil when no new messages' do
      stub(JSON).load_file(path) { one_wip_msg }

      expect(sut.first_new).to be_nil
    end

    it 'returns nil when inbox missing' do
      stub(File).exist?(path) { false }

      expect(sut.first_new).to be_nil
    end

    it 'returns nil when JSON is malformed' do
      stub(JSON).load_file(path) { raise JSON::ParserError }

      expect(sut.first_new).to be_nil
    end
  end
end
