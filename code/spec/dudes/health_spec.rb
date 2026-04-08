require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/health'

describe Dude::Dudes::Health do
  let(:health) { described_class.new }
  let(:dir) { '/proj/.claude/dudes' }

  before do
    allow_any_instance_of(Dude::Dudes::Health).to receive(:`).and_return("")
    allow(Process).to receive(:kill)
    allow(File).to receive(:write)
  end

  it 'returns alive pid' do
    pgrep_pattern = /pgrep -f/
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(pgrep_pattern).and_return("123\n")
    )
    expect(health.check(dir, { 'abide_pid' => 123 })[:pid_alive]).to eq(123)
  end

  it 'returns nil when no processes' do
    expect(health.check(dir, {})[:pid_alive]).to be_nil
  end

  it 'kills orphaned process' do
    pgrep_pattern = /pgrep -f/
    ps_pattern = /ps -p/
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(pgrep_pattern).and_return("456\n")
    )
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(ps_pattern).and_return("1\n")
    )
    expect(health.check(dir, {})[:pid_alive]).to be_nil
    expect(Process).to have_received(:kill).with('TERM', 456)
  end

  it 'updates status when pid changed' do
    pgrep_pattern = /pgrep -f/
    ps_pattern = /ps -p/
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(pgrep_pattern).and_return("789\n")
    )
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(ps_pattern).and_return("999\n")
    )
    health.check(dir, { 'abide_pid' => 111 })
    expect(File).to have_received(:write)
  end

  it 'skips update when pid unchanged' do
    pgrep_pattern = /pgrep -f/
    ps_pattern = /ps -p/
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(pgrep_pattern).and_return("123\n")
    )
    allow_any_instance_of(Dude::Dudes::Health).to(
      receive(:`).with(ps_pattern).and_return("999\n")
    )
    health.check(dir, { 'abide_pid' => 123 })
    expect(File).not_to have_received(:write)
  end
end
