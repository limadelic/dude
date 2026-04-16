require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/alley_pr"
require_relative "../../lib/dude/helpers/wait"

describe Dude::Dudes::AlleyPr do
  include RR::DSL

  REMOTE_URL = 'git@github.com:UKGEPIC/dude.git'
  BASE_MOCKS = {
    'git branch --show-current' => 'feature-branch',
    'git remote get-url origin' => REMOTE_URL,
    'git push' => '',
    'gh workflow run dude.yml' => '',
    'gh run list json databaseId' => '12345',
    'gh run list json status' => 'completed',
    'gh run view 12345 json conclusion' => 'success'
  }.freeze

  let(:sut) { described_class.new }
  let(:wait) { Object.new }

  before do
    @mocks = {}
    allow_any_instance_of(Object).to receive(:`) do |_, cmd|
      match = @mocks.find { |pat, _| pat.split.all? { |w| cmd.include?(w) } }
      match&.last || ''
    end
    stub(Dude::Helpers::Wait).new { wait }
    stub(wait).until { |&block| block.call }
  end

  describe '#execute' do
    context 'on main branch' do
      it 'raises error' do
        @mocks['git branch --show-current'] = 'main'
        expect { sut.execute }.to raise_error('Cannot run on main branch')
      end
    end

    context 'happy path' do
      before do
        @mocks.update(BASE_MOCKS)
        @mocks['gh pr list head feature-branch json url'] = 'https://github.com/UKGEPIC/dude/pull/123'
        @mocks['pbcopy'] = ''
        @mocks['git commit'] = ''
      end

      it 'executes full sequence and returns PR URL' do
        expect(sut.execute).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end
    end

    context 'workflow fails' do
      before do
        @mocks.update(BASE_MOCKS)
        @mocks['gh run view 12345 json conclusion'] = 'failure'
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error(
          'Workflow failed: https://github.com/UKGEPIC/dude/actions/runs/12345'
        )
      end
    end

    context 'no PR found' do
      before do
        @mocks.update(BASE_MOCKS)
        @mocks['gh pr list head feature-branch json url'] = ''
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error(
          'No PR found: https://github.com/UKGEPIC/dude/actions/runs/12345'
        )
      end
    end

    context 'multiple PRs found' do
      before do
        @mocks.update(BASE_MOCKS)
        @mocks['gh pr list head feature-branch json url'] =
          "https://github.com/UKGEPIC/dude/pull/122\nhttps://github.com/UKGEPIC/dude/pull/123"
        @mocks['pbcopy'] = ''
        @mocks['git commit'] = ''
      end

      it 'uses newest PR and warns' do
        mock($stdout).puts(/Multiple PRs found, using newest/)
        expect(sut.execute).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end
    end
  end
end
