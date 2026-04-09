require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_revert"

describe Dude::Dudes::GitRevert do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#execute' do
    it 'reverts each file with git checkout' do
      stub(Kernel).system("git checkout lib/foo.rb") { true }

      sut.execute
    end

    it 'reverts multiple files' do
      stub(Kernel).system(/git checkout /) { true }

      sut_multi = described_class.new(%w[lib/foo.rb lib/bar.rb])
      sut_multi.execute
    end
  end
end
