require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/inbox'

describe Dude::Dudes::Inbox do
  let(:path) { '/root/.claude/dudes/inbox.json' }
  let(:inbox) { described_class.new(path) }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(JSON).to receive(:load_file) { [] }
    allow(File).to receive(:write)
  end

  describe '#append' do
    it 'adds message to empty inbox' do
      inbox.append({ 'text' => 'hi' })
      expect(File).to have_received(:write).with(path, '[{"text":"hi"}]')
    end

    it 'appends to existing messages' do
      allow(JSON).to receive(:load_file) {
        [{ 'text' => 'old', 'status' => 'new' }]
      }
      inbox.append({ 'text' => 'hi' })
      expect(File).to have_received(:write).with(
        path,
        '[{"text":"old","status":"new"},{"text":"hi"}]'
      )
    end
  end

  describe '#mark_wip' do
    it 'sets first item status to wip' do
      allow(JSON).to receive(:load_file) {
        [{ 'text' => 'hi', 'status' => 'new' }]
      }
      inbox.mark_wip
      expect(File).to have_received(:write).with(
        path,
        '[{"text":"hi","status":"wip"}]'
      )
    end

    it 'does nothing on empty inbox' do
      inbox.mark_wip
      expect(File).not_to have_received(:write)
    end
  end

  describe '#dequeue_wip' do
    it 'removes first item if wip' do
      allow(JSON).to receive(:load_file) {
        [
          { 'text' => 'hi', 'status' => 'wip' },
          { 'text' => 'bye', 'status' => 'new' }
        ]
      }
      inbox.dequeue_wip
      expect(File).to have_received(:write).with(
        path,
        '[{"text":"bye","status":"new"}]'
      )
    end

    it 'does not remove if not wip' do
      allow(JSON).to receive(:load_file) {
        [{ 'text' => 'hi', 'status' => 'new' }]
      }
      inbox.dequeue_wip
      expect(File).not_to have_received(:write)
    end
  end

  describe '#first_new' do
    it 'returns first new message' do
      allow(JSON).to receive(:load_file) {
        [{ 'text' => 'hi', 'status' => 'new' }]
      }
      expect(inbox.first_new).to eq({ 'text' => 'hi', 'status' => 'new' })
    end

    it 'returns nil when no new messages' do
      allow(JSON).to receive(:load_file) {
        [{ 'text' => 'hi', 'status' => 'wip' }]
      }
      expect(inbox.first_new).to be_nil
    end

    it 'returns nil when inbox missing' do
      allow(File).to receive(:exist?).and_return(false)
      expect(inbox.first_new).to be_nil
    end
  end
end
