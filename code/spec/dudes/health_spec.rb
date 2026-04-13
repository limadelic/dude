require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/health'

describe Dude::Dudes::Health do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:dir) { '/proj/.claude/dudes' }
  let(:pattern) { 'wait-until.*' + File.join(dir, 'inbox.json') }

  describe '#check' do
    it 'returns alive pid when process is running' do
      stub(sut).`("pgrep -f \"#{pattern}\"") { "123\n" }
      stub(sut).`("ps -p 123 -o ppid=") { "999\n" }

      result = sut.check(dir, { 'abide_pid' => 123 })

      expect(result[:pid_alive]).to eq(123)
    end

    it 'returns nil when no processes found' do
      stub(sut).`("pgrep -f \"#{pattern}\"") { "" }

      result = sut.check(dir, {})

      expect(result[:pid_alive]).to be_nil
    end

    it 'returns nil for orphaned process' do
      stub(sut).`("pgrep -f \"#{pattern}\"") { "456\n" }
      stub(sut).`("ps -p 456 -o ppid=") { "1\n" }
      mock(Process).kill('TERM', 456)

      result = sut.check(dir, {})

      expect(result[:pid_alive]).to be_nil
    end

    it 'updates status when pid changed' do
      stub(sut).`("pgrep -f \"#{pattern}\"") { "789\n" }
      stub(sut).`("ps -p 789 -o ppid=") { "999\n" }
      mock(File).write("/proj/.claude/dudes/status.json", anything)

      result = sut.check(dir, { 'abide_pid' => 111 })

      expect(result[:pid_alive]).to eq(789)
    end

    it 'does not update status when pid unchanged' do
      stub(sut).`("pgrep -f \"#{pattern}\"") { "123\n" }
      stub(sut).`("ps -p 123 -o ppid=") { "999\n" }
      dont_allow(File).write

      result = sut.check(dir, { 'abide_pid' => 123 })

      expect(result[:pid_alive]).to eq(123)
    end
  end
end
