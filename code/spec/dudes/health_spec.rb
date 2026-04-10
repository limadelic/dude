require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/health'

describe Dude::Dudes::Health do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:dir) { '/proj/.claude/dudes' }

  describe '#check' do
    before do
      stub(sut).`(/pgrep -f.*/) { "123\n" }
      stub(sut).`(/ps -p.*/) { "999\n" }
    end

    it 'returns alive pid when process is running' do
      result = sut.check(dir, { 'abide_pid' => 123 })

      expect(result[:pid_alive]).to eq(123)
    end

    it 'returns nil when no processes found' do
      stub(sut).`(/pgrep -f.*/) { "" }

      result = sut.check(dir, {})

      expect(result[:pid_alive]).to be_nil
    end

    it 'kills orphaned process and returns nil' do
      stub(sut).`(/pgrep -f.*/) { "456\n" }
      stub(sut).`(/ps -p.*/) { "1\n" }
      mock(Process).kill('TERM', 456)

      result = sut.check(dir, {})

      expect(result[:pid_alive]).to be_nil
    end

    it 'updates status when pid changed' do
      stub(sut).`(/pgrep -f.*/) { "789\n" }
      stub(sut).`(/ps -p.*/) { "999\n" }
      mock(File).write(/status\.json/, /abide_pid/)

      sut.check(dir, { 'abide_pid' => 111 })
    end

    it 'does not update status when pid unchanged' do
      stub(sut).`(/pgrep -f.*/) { "123\n" }
      stub(sut).`(/ps -p.*/) { "999\n" }
      mock(File).write.never

      sut.check(dir, { 'abide_pid' => 123 })
    end
  end
end
