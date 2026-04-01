require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/dude'

describe Dude::Dudes::Dude do
  let(:dude_dir) { '/proj/.claude/dudes' }
  let(:reg_m) { instance_double('Dude::Dudes::Dudes') }

  def build(overrides = {})
    h = {
      icon: '🔴', inbox: [], status: {}, dude_dir: dude_dir,
      target: '/proj/.claude', name: 'rec', registry: overrides[:registry] || reg_m
    }
    described_class.new(h.merge(overrides))
  end

  describe '#is_current?' do
    it 'returns false when pid is nil' do
      registry_mock = instance_double('Dude::Dudes::Dudes')
      expect(registry_mock).not_to receive(:is_current?)
      dude = build(registry: registry_mock)
      dude.pid = nil
      expect(dude).not_to be_is_current
    end

    it 'returns true when registry says current' do
      registry_mock = instance_double('Dude::Dudes::Dudes')
      expect(registry_mock).to receive(:is_current?).with(999).and_return(true)
      dude = build(registry: registry_mock)
      dude.pid = 999
      expect(dude).to be_is_current
    end
  end

  describe '#messages' do
    it 'returns inbox count' do
      expect(build(inbox: [{}, {}, {}]).messages).to eq(3)
    end

    it 'zero when empty' do
      expect(build.messages).to eq(0)
    end
  end

  describe '#context' do
    it 'returns context from status' do
      expect(build(status: { 'context' => 50 }).context).to eq(50)
    end

    it 'defaults to 0' do
      expect(build.context).to eq(0)
    end
  end

  describe '#tell' do
    it 'raises when target dude not found' do
      allow(File).to receive(:symlink?).and_return(false)
      dude = build(name: 'smith', inbox: instance_double('Dudes::Inbox'))
      expect { dude.tell('rec', 'hi') }.to raise_error("dude 'rec' not found")
    end
  end

  describe '#ask' do
    it 'raises when target dude not found' do
      allow(File).to receive(:symlink?).and_return(false)
      dude = build(name: 'smith', inbox: instance_double('Dudes::Inbox'))
      expect { dude.ask('rec', 'hi') }.to raise_error("dude 'rec' not found")
    end
  end

  describe '#pub' do
    it 'uses name as default icon' do
      pub_mock = instance_double('Dude::Dudes::Pub')
      expect(pub_mock).to receive(:pub).with(
        '/proj/.claude',
        'rec'
      ).and_return('rec')
      allow(Dude::Dudes::Pub).to receive(:new).and_return(pub_mock)

      dude = build(target: '/proj/.claude', name: 'rec')
      result = dude.pub(nil)

      expect(result).to eq('rec')
    end
  end

  describe '#append' do
    it 'appends message to own inbox' do
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      expect(inbox_mock).to receive(:append).with({ 'text' => 'hi' })
      dude = build(dude_dir: '/proj/.claude/dudes', inbox: inbox_mock)
      dude.append({ 'text' => 'hi' })
    end
  end

  describe '#first_new' do
    it 'returns first new message from own inbox' do
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      msg = { 'text' => 'hello', 'status' => 'new' }
      expect(inbox_mock).to receive(:first_new).and_return(msg)
      dude = build(dude_dir: '/proj/.claude/dudes', inbox: inbox_mock)
      expect(dude.first_new).to eq(msg)
    end

    it 'returns nil when no new messages' do
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      expect(inbox_mock).to receive(:first_new).and_return(nil)
      dude = build(dude_dir: '/proj/.claude/dudes', inbox: inbox_mock)
      expect(dude.first_new).to be_nil
    end
  end

  describe '#mark_wip' do
    it 'marks first message as wip in own inbox' do
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      expect(inbox_mock).to receive(:mark_wip)
      dude = build(dude_dir: '/proj/.claude/dudes', inbox: inbox_mock)
      dude.mark_wip
    end
  end

  describe '#dequeue_wip' do
    it 'dequeues wip message from own inbox' do
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      expect(inbox_mock).to receive(:dequeue_wip)
      dude = build(dude_dir: '/proj/.claude/dudes', inbox: inbox_mock)
      dude.dequeue_wip
    end
  end

  describe '#is_abiding?' do
    it 'returns true when registry says abiding' do
      registry_mock = instance_double('Dude::Dudes::Dudes')
      expect(registry_mock).to receive(:is_abiding?).with(
        888,
        '/proj/.claude/dudes', '/proj/.claude'
      ).and_return(true)
      dude = build(registry: registry_mock)
      dude.pid = 888
      expect(dude).to be_is_abiding
    end
  end

  describe '#tell' do
    it 'sends a message that arrives in target inbox' do
      target_inbox_path = '/projects/rec/.claude/dudes/inbox.json'
      target_inbox_mock = instance_double('Dude::Dudes::Inbox')
      msg = { 'text' => 'hello', 'status' => 'new' }
      expect(target_inbox_mock).to receive(:append).with(msg)
      expect(Dude::Dudes::Inbox).to(
        receive(:new).with(target_inbox_path).and_return(target_inbox_mock)
      )
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/projects/rec/.claude/')

      dude = build(name: 'smith')
      dude.tell('rec', 'hello')
    end
  end

  describe '#ask' do
    it 'sends a message with from field to target inbox' do
      target_inbox_path = '/projects/rec/.claude/dudes/inbox.json'
      target_inbox_mock = instance_double('Dude::Dudes::Inbox')
      msg = { 'from' => 'smith', 'text' => 'whatup', 'status' => 'new' }
      expect(target_inbox_mock).to receive(:append).with(msg)
      expect(Dude::Dudes::Inbox).to(
        receive(:new).with(target_inbox_path).and_return(target_inbox_mock)
      )
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/projects/rec/.claude/')

      dude = build(name: 'smith')
      dude.ask('rec', 'whatup')
    end
  end

  describe '#pub' do
    it 'calls pub and returns icon' do
      pub_mock = instance_double('Dude::Dudes::Pub')
      expect(pub_mock).to receive(:pub).with(
        '/proj/.claude',
        'custom_icon'
      ).and_return('custom_icon')
      allow(Dude::Dudes::Pub).to receive(:new).and_return(pub_mock)

      dude = build(target: '/proj/.claude')
      result = dude.pub('custom_icon')

      expect(result).to eq('custom_icon')
    end
  end

  describe '#unpub' do
    it 'calls unpub' do
      pub_mock = instance_double('Dude::Dudes::Pub')
      expect(pub_mock).to receive(:unpub).with('/proj/.claude')
      allow(Dude::Dudes::Pub).to receive(:new).and_return(pub_mock)

      dude = build(target: '/proj/.claude')
      dude.unpub
    end
  end

  describe '#pids_for_target' do
    it 'returns pids from registry' do
      registry_mock = instance_double('Dude::Dudes::Dudes')
      pids = [111, 222]
      expect(registry_mock).to(
        receive(:pids_for_target).with('/proj/.claude').and_return(pids)
      )
      dude = build(registry: registry_mock, target: '/proj/.claude')
      result = dude.pids_for_target

      expect(result).to eq(pids)
    end
  end

  describe '#watch' do
    it 'returns first new message and marks it wip' do
      msg = { 'text' => 'hello', 'status' => 'new' }
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      expect(inbox_mock).to receive(:first_new).and_return(msg)
      expect(inbox_mock).to receive(:mark_wip)

      dude = build(inbox: inbox_mock)
      result = dude.watch

      expect(result).to eq(msg)
    end
  end

  describe '#abided' do
    it 'dequeues wip message' do
      inbox_mock = instance_double('Dude::Dudes::Inbox')
      expect(inbox_mock).to receive(:mark_wip)
      expect(inbox_mock).to receive(:dequeue_wip)

      dude = build(inbox: inbox_mock)
      dude.abided
    end
  end

  describe '#sub' do
    it 'delegates to pub.sub with target and name' do
      pub_mock = instance_double('Dude::Dudes::Pub')
      expect(pub_mock).to receive(:sub).with(
        '/proj/.claude',
        'code'
      ).and_return('dude_code')
      allow(Dude::Dudes::Pub).to receive(:new).and_return(pub_mock)

      dude = build(target: '/proj/.claude')
      result = dude.sub('code')

      expect(result).to eq('dude_code')
    end

    it 'defaults name to target basename when not provided' do
      pub_mock = instance_double('Dude::Dudes::Pub')
      expect(pub_mock).to receive(:sub).with(
        '/proj/.claude',
        nil
      ).and_return('dude_claude')
      allow(Dude::Dudes::Pub).to receive(:new).and_return(pub_mock)

      dude = build(target: '/proj/.claude')
      result = dude.sub

      expect(result).to eq('dude_claude')
    end
  end
end
