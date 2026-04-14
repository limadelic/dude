require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_stage_commit"

describe Dude::Dudes::GitStageCommit do
  include RR::DSL

  let(:sut) { described_class.new(files) }

  describe '#execute' do
    context 'with single file' do
      let(:files) { %w[lib/foo.rb] }

      it 'stages the file and commits' do
        mock(sut).system('git add lib/foo.rb')
        mock(sut).system(/git commit/)

        sut.execute
      end
    end

    context 'with multiple files' do
      let(:files) { %w[lib/foo.rb lib/bar.rb] }

      it 'stages all files and commits' do
        mock(sut).system('git add lib/foo.rb')
        mock(sut).system('git add lib/bar.rb')
        mock(sut).system(/git commit/)

        sut.execute
      end
    end
  end
end
