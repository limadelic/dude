require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/git_stage_commit"

describe 'Dude::Dudes::GitStageCommit' do
  let(:described_class) { Dude::Dudes::GitStageCommit }
  let(:git) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#execute' do
    it 'stages and commits files' do
      allow(git).to receive(:system).and_return(true)

      git.execute
    end
  end
end
