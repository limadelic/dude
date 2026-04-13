require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_stage_commit"

describe Dude::Dudes::GitStageCommit do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#execute' do
    before do
      mock(sut).system(/git add/).at_least(1)
      mock(sut).system(/git commit/).once
    end

    it 'stages each file and commits' do
      sut.execute
    end

    context 'with multiple files' do
      let(:files) { %w[lib/foo.rb lib/bar.rb] }

      it 'stages all files' do
        sut.execute
      end
    end
  end
end
