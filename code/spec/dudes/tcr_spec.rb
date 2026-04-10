require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tcr"

describe Dude::Dudes::Tcr do
  include RR::DSL

  let(:files) { %w[file.rb] }
  let(:sut) { described_class.new(files) }
  let(:tests_runner) { Object.new }
  let(:linter) { Object.new }
  let(:commit) { Object.new }
  let(:revert) { Object.new }

  before do
    stub(Dude::Dudes::TestsRunner).new(files) { tests_runner }
    stub(Dude::Dudes::Linter).new(files) { linter }
    stub(Dude::Dudes::GitStageCommit).new(files) { commit }
    stub(Dude::Dudes::GitRevert).new(files) { revert }
    stub(tests_runner).pass? { true }
    stub(linter).pass? { true }
  end

  describe '#run' do
    it 'returns true when tests and lint pass' do
      mock(commit).execute

      expect(sut.run).to eq(true)
    end

    it 'returns false when tests fail' do
      stub(tests_runner).pass? { false }
      mock(revert).execute

      expect(sut.run).to eq(false)
    end

    it 'returns false when lint fails' do
      stub(linter).pass? { false }
      mock(revert).execute

      expect(sut.run).to eq(false)
    end
  end
end
