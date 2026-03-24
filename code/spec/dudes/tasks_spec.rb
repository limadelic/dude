require_relative '../spec_helper'
require_relative '../../lib/dudes/tasks'

describe Dudes::Tasks do
  let(:fs) { instance_double(Helpers::FS) }
  let(:tasks) { described_class.new(fs) }
  let(:dir) { '/root/.claude/dudes' }

  before do
    allow(fs).to receive(:dir_exist?).and_return(true)
    allow(fs).to receive(:newest_child).and_return('/tmp/abc-123.jsonl')
    allow(fs).to receive(:children).and_return(['1.json'])
    allow(fs).to receive(:read).and_return('{}')
  end

  it 'true when abide task exists' do
    allow(fs).to receive(:read).and_return({ subject: 'Abide rec: do stuff' }.to_json)
    expect(tasks.has_abide?(dir)).to be true
  end

  it 'false when no abide task' do
    allow(fs).to receive(:read).and_return({ subject: 'Fix bug' }.to_json)
    expect(tasks.has_abide?(dir)).to be false
  end

  it 'false when no project dir' do
    allow(fs).to receive(:dir_exist?).and_return(false)
    expect(tasks.has_abide?(dir)).to be false
  end

  it 'false when no session' do
    allow(fs).to receive(:newest_child).and_return(nil)
    expect(tasks.has_abide?(dir)).to be false
  end

  it 'false on error' do
    allow(fs).to receive(:dir_exist?).and_raise(Errno::EACCES)
    expect(tasks.has_abide?(dir)).to be false
  end
end
