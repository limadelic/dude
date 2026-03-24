require_relative '../spec_helper'
require_relative '../../lib/dudes/health'

describe Dudes::Health do
  let(:fs) { instance_double(Helpers::FS) }
  let(:health) { described_class.new(fs) }
  let(:dir) { '/proj/.claude/dudes' }

  before do
    allow(fs).to receive(:pgrep_all).and_return([])
    allow(fs).to receive(:orphaned?).and_return(false)
    allow(fs).to receive(:kill)
    allow(fs).to receive(:write)
  end

  it 'returns alive pid' do
    allow(fs).to receive(:pgrep_all).and_return([123])
    expect(health.check(dir, { 'abide_pid' => 123 })[:pid_alive]).to eq(123)
  end

  it 'returns nil when no processes' do
    expect(health.check(dir, {})[:pid_alive]).to be_nil
  end

  it 'kills orphaned process' do
    allow(fs).to receive(:pgrep_all).and_return([456])
    allow(fs).to receive(:orphaned?).and_return(true)
    expect(health.check(dir, {})[:pid_alive]).to be_nil
    expect(fs).to have_received(:kill).with(456)
  end

  it 'updates status when pid changed' do
    allow(fs).to receive(:pgrep_all).and_return([789])
    health.check(dir, { 'abide_pid' => 111 })
    expect(fs).to have_received(:write)
  end

  it 'skips update when pid unchanged' do
    allow(fs).to receive(:pgrep_all).and_return([123])
    health.check(dir, { 'abide_pid' => 123 })
    expect(fs).not_to have_received(:write)
  end
end
