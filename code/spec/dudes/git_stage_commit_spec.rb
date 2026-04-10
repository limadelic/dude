require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_stage_commit"

describe Dude::Dudes::GitStageCommit do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#execute' do
    it 'stages each file with git add' do
      mock(sut).system("git add lib/foo.rb")
      mock(sut).system(/git commit/)

      sut.execute
    end

    it 'commits all staged files with TCR message' do
      mock(sut).system(/git add/)
      mock(sut).system("git commit -m \"TCR: auto-commit\" 2>&1")

      sut.execute
    end

    context 'with multiple files' do
      let(:files) { %w[lib/foo.rb lib/bar.rb] }

      it 'stages all files' do
        mock(sut).system("git add lib/foo.rb")
        mock(sut).system("git add lib/bar.rb")
        mock(sut).system(/git commit/)

        sut.execute
      end
    end
  end
end
