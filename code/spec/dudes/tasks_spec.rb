require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/tasks'

describe Dude::Dudes::Tasks do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:dude_dir) { '/root/.claude/dudes' }
  let(:project_dir) { File.join(File.expand_path('~/.claude/projects'), '-root--claude') }
  let(:tasks_dir) { File.join(File.expand_path('~/.claude/tasks'), 'abc-123') }

  describe '#has_abide?' do
    before do
      stub(Dir).exist?(anything) { true }
      stub(Dir).children(project_dir) { ['abc-123.jsonl'] }
      stub(File).mtime(anything) { Time.now }
      stub(Dir).children(tasks_dir) { ['1.json'] }
      stub(JSON).load_file(anything) { {} }
    end

    it 'returns true when abide task exists' do
      stub(JSON).load_file(/1\.json/) { { 'subject' => 'Abide rec: do stuff' } }

      expect(sut.has_abide?(dude_dir)).to be true
    end

    it 'returns false when no abide task' do
      stub(JSON).load_file(/1\.json/) { { 'subject' => 'Fix bug' } }

      expect(sut.has_abide?(dude_dir)).to be false
    end

    it 'returns false when no project dir' do
      stub(Dir).exist?(anything) { false }

      expect(sut.has_abide?(dude_dir)).to be false
    end

    it 'returns false when no session' do
      stub(Dir).children(project_dir) { [] }

      expect(sut.has_abide?(dude_dir)).to be false
    end

    it 'returns false on error' do
      stub(Dir).exist?(anything) { raise Errno::EACCES }

      expect(sut.has_abide?(dude_dir)).to be false
    end
  end
end
