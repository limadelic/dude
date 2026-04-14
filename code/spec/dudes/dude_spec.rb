require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/dude'

describe Dude::Dudes::Dude do
  include RR::DSL

  let(:sut) { described_class.new(defaults.merge(overrides)) }
  let(:overrides) { {} }
  let(:registry) { Object.new }
  let(:inbox) { Object.new }
  let(:pub) { Object.new }
  let(:target_inbox) { Object.new }
  let(:msg) { { 'text' => 'hi' } }
  let(:tell_msg) { { 'text' => 'hello', 'status' => 'new' } }
  let(:ask_msg) { { 'from' => 'smith', 'text' => 'whatup', 'status' => 'new' } }
  let(:new_msg) { { 'text' => 'hello', 'status' => 'new' } }

  let(:defaults) do
    {
      name: 'rec', icon: 'icon', status: {}, dude_dir: '/proj/.claude/dudes',
      target: '/proj/.claude', registry: registry, inbox: inbox
    }
  end

  before do
    stub(Dude::Dudes::Pub).new { pub }
  end

  describe '#is_current?' do
    it 'returns false when pid is nil' do
      expect(sut).not_to be_is_current
    end

    it 'returns true when registry says current' do
      stub(registry).is_current?(999) { true }

      expect(sut_with(pid: 999)).to be_is_current
    end
  end

  describe '#messages' do
    it 'counts inbox items' do
      stub(inbox).length { 3 }

      expect(sut.messages).to eq(3)
    end

    it 'returns zero when inbox empty' do
      stub(inbox).length { 0 }

      expect(sut.messages).to eq(0)
    end
  end

  describe '#context' do
    it 'returns context from status hash' do
      context_value = 50
      expect(sut_with(status: { 'context' => context_value }).context)
        .to eq(context_value)
    end

    it 'defaults to 0 when context missing' do
      expect(sut_with(status: {}).context).to eq(0)
    end
  end

  shared_context 'target dude stubs' do
    before do
      stub(File).symlink?(/rec/) { true }
      stub(File).readlink(/rec/) { '/projects/rec/.claude/' }
      stub(Dude::Dudes::Inbox).new(/rec.*inbox\.json/) { target_inbox }
    end
  end

  describe '#tell' do
    include_context 'target dude stubs'

    it 'raises when target dude not found' do
      stub(File).symlink?(/rec/) { false }

      expect { sut_with(name: 'smith').tell('rec', 'hi') }
        .to raise_error("dude 'rec' not found")
    end

    it 'delivers message to target inbox' do
      mock(target_inbox).append(tell_msg)

      sut_with(name: 'smith').tell('rec', 'hello')
    end
  end

  describe '#ask' do
    include_context 'target dude stubs'

    it 'raises when target dude not found' do
      stub(File).symlink?(/rec/) { false }

      expect { sut_with(name: 'smith').ask('rec', 'hi') }
        .to raise_error("dude 'rec' not found")
    end

    it 'includes from field in message' do
      mock(target_inbox).append(ask_msg)

      sut_with(name: 'smith').ask('rec', 'whatup')
    end
  end

  describe '#pub' do
    it 'publishes with name when icon not provided' do
      stub(pub).pub('/proj/.claude', 'rec') { 'rec' }

      expect(sut.pub(nil)).to eq('rec')
    end

    it 'publishes with custom icon' do
      stub(pub).pub('/proj/.claude', 'custom_icon') { 'custom_icon' }

      expect(sut.pub('custom_icon')).to eq('custom_icon')
    end
  end

  describe '#unpub' do
    it 'removes publication' do
      mock(pub).unpub('/proj/.claude')

      sut.unpub
    end
  end

  describe '#append' do
    it 'adds message to own inbox' do
      mock(inbox).append(msg)

      sut.append(msg)
    end
  end

  describe '#first_new' do
    it 'returns first new message' do
      stub(inbox).first_new { new_msg }

      expect(sut.first_new).to eq(new_msg)
    end

    it 'returns nil when no new messages' do
      stub(inbox).first_new { nil }

      expect(sut.first_new).to be_nil
    end
  end

  describe '#mark_wip' do
    it 'marks first message as work in progress' do
      mock(inbox).mark_wip

      sut.mark_wip
    end
  end

  describe '#dequeue_wip' do
    it 'removes wip message from inbox' do
      mock(inbox).dequeue_wip

      sut.dequeue_wip
    end
  end

  describe '#is_abiding?' do
    it 'delegates to registry with pid and paths' do
      stub(registry).is_abiding?(888, '/proj/.claude/dudes', '/proj/.claude') {
        true
      }

      expect(sut_with(pid: 888)).to be_is_abiding
    end
  end

  describe '#pids_for_target' do
    it 'returns pids from registry for target' do
      pids = [111, 222]
      stub(registry).pids_for_target('/proj/.claude') { pids }

      expect(sut.pids_for_target).to eq(pids)
    end
  end

  describe '#watch' do
    it 'returns first new message and marks as wip' do
      stub(inbox).first_new { new_msg }
      mock(inbox).mark_wip

      expect(sut.watch).to eq(new_msg)
    end
  end

  describe '#abided' do
    it 'marks wip then dequeues it' do
      mock(inbox).mark_wip
      mock(inbox).dequeue_wip

      sut.abided
    end
  end

  describe '#sub' do
    it 'subscribes with provided name' do
      stub(pub).sub('/proj/.claude', 'code') { 'dude_code' }

      expect(sut.sub('code')).to eq('dude_code')
    end

    it 'subscribes with nil when name not provided' do
      stub(pub).sub('/proj/.claude', nil) { 'dude_claude' }

      expect(sut.sub).to eq('dude_claude')
    end
  end

  private

  def sut_with(overrides = {})
    described_class.new(defaults.merge(overrides))
  end
end
