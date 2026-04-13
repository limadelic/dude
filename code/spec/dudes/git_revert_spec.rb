require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_revert"

describe Dude::Dudes::GitRevert do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#execute' do
    before do
      mock(sut).system(/git checkout/).at_least(1)
    end

    it 'restores single file to HEAD' do
      sut.execute
    end

    context 'with multiple files' do
      let(:files) { %w[lib/foo.rb lib/bar.rb] }

      it 'restores all files to HEAD' do
        sut.execute
      end
    end
  end
end
