require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_revert"

describe 'Dude::Dudes::GitRevert' do
  let(:described_class) { Dude::Dudes::GitRevert }
  let(:revert) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#execute' do
    it 'reverts files with git checkout' do
      allow(revert).to receive(:system).and_return(true)

      revert.execute
    end
  end
end
