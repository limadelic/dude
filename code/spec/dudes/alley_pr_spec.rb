require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/alley_pr"
require_relative "../../lib/dude/helpers/wait"

describe Dude::Dudes::AlleyPr do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:wait) { Object.new }

  before do
    stub(Dude::Helpers::Wait).new { wait }
    stub(wait).until { |&block| block.call }
  end

  describe '#execute' do
    context 'on main branch' do
      it 'raises error' do
        stub(sut).`('git branch --show-current') { 'main' }
        expect { sut.execute }.to raise_error('Cannot run on main branch')
      end
    end

    before do
      stub(sut).`('git branch --show-current') { 'feature-branch' }
      stub(sut).`(/git push/) { '' }
      stub(sut).`(/gh workflow run/) { '' }
      stub(sut).`(/gh run list.*databaseId/) { '12345' }
      stub(sut).`(/gh run list.*status/) { 'completed' }
      stub(sut).`(/git remote get-url/) { 'git@github.com:BuildBot/dude.git' }
      stub(sut).`(/gh run view.*conclusion/) { 'success' }
      stub(sut).`(/gh pr list.*head/) { 'https://github.com/BuildBot/dude/pull/123' }
      stub(sut).`(/pbcopy/) { '' }
      stub(sut).`(/git commit/) { '' }
      stub(sut).configured_workflow_org { 'BuildBot' }
    end

    context 'happy path' do
      it 'executes full sequence and returns PR URL' do
        expect(sut.execute).to eq 'https://github.com/BuildBot/dude/pull/123'
      end
    end

    context 'workflow fails' do
      before do
        stub(sut).`(/gh run view.*conclusion/) { 'failure' }
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error(
          'Workflow failed: https://github.com/BuildBot/dude/actions/runs/12345'
        )
      end
    end

    context 'no PR found' do
      before do
        stub(sut).`(/gh pr list.*head/) { '' }
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error(
          'No PR found: https://github.com/BuildBot/dude/actions/runs/12345'
        )
      end
    end

    context 'multiple PRs found' do
      before do
        stub(sut).`(/gh pr list.*head/) {
          "https://github.com/BuildBot/dude/pull/122\nhttps://github.com/BuildBot/dude/pull/123"
        }
      end

      it 'uses newest PR and warns' do
        mock($stdout).puts(/Multiple PRs found, using newest/)
        expect(sut.execute).to eq 'https://github.com/BuildBot/dude/pull/123'
      end
    end

    context 'workflow not configured' do
      before do
        stub(sut).configured_workflow_org { nil }
        stub(sut).`(/git remote get-url/) { 'git@github.com:foo/bar.git' }
        stub(sut).`(/gh pr create --fill/) { 'https://github.com/foo/bar/pull/1' }
      end

      it 'creates PR via gh cli' do
        expect(sut.execute).to eq 'https://github.com/foo/bar/pull/1'
      end
    end
  end
end
