require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/tasks'

describe Dude::Dudes::Tasks do
  let(:tasks) { described_class.new }
  let(:dir) { '/root/.claude/dudes' }
  let(:project_dir) do
    File.join(File.expand_path('~/.claude/projects'), '-root--claude')
  end
  let(:tasks_dir) do
    File.join(File.expand_path('~/.claude/tasks'), 'abc-123')
  end

  before do
    allow(Dir).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:children).with(project_dir)
      .and_return(['abc-123.jsonl'])
    allow(File).to receive(:mtime).and_return(Time.now)
    allow(Dir).to receive(:children).with(tasks_dir).and_return(['1.json'])
    allow(JSON).to receive(:load_file).and_return({})
  end

  it 'true when abide task exists' do
    allow(JSON).to receive(:load_file).and_return(
      { 'subject' => 'Abide rec: do stuff' }
    )
    expect(tasks.has_abide?(dir)).to be true
  end

  it 'false when no abide task' do
    allow(JSON).to receive(:load_file).and_return({ 'subject' => 'Fix bug' })
    expect(tasks.has_abide?(dir)).to be false
  end

  it 'false when no project dir' do
    allow(Dir).to receive(:exist?).with(project_dir).and_return(false)
    expect(tasks.has_abide?(dir)).to be false
  end

  it 'false when no session' do
    allow(Dir).to receive(:children).with(project_dir).and_return([])
    expect(tasks.has_abide?(dir)).to be false
  end

  it 'false on error' do
    allow(Dir).to receive(:exist?).and_raise(Errno::EACCES)
    expect(tasks.has_abide?(dir)).to be false
  end
end
