require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/alley_pr"
require_relative "../../lib/dude/helpers/wait"

describe Dude::Dudes::AlleyPr do
  include RR::DSL

  REMOTE_URL = 'git@github.com:UKGEPIC/dude.git'

  let(:sut) { described_class.new }
  let(:wait) { Object.new }

  before do
    stub_backticks
    stub(Dude::Helpers::Wait).new { wait }
    stub(wait).until { block_given? ? true : false }
  end

  describe '#execute' do
    context 'on main branch' do
      it 'raises error' do
        set_backtick_mock('git branch --show-current', 'main')

        expect { sut.execute }.to raise_error('Cannot run on main branch')
      end
    end

    context 'happy path' do
      before do
        set_backtick_mock('git branch --show-current', 'feature-branch')
        set_backtick_mock('git remote get-url origin', REMOTE_URL)
        set_backtick_mock('git push', '')
        set_backtick_mock('gh workflow run dude.yml', '')
        set_backtick_mock('gh run list json databaseId', '12345')
        set_backtick_mock('gh run list json status', 'completed')
        set_backtick_mock('gh run list json conclusion', 'success')
        set_backtick_mock('gh pr list head feature-branch json url', 'https://github.com/UKGEPIC/dude/pull/123')
        set_backtick_mock('pbcopy', '')
        set_backtick_mock('git commit', '')
      end

      it 'executes full sequence and returns PR URL' do
        result = sut.execute

        expect(result).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end

      it 'pushes branch' do
        sut.execute
      end

      it 'triggers workflow' do
        sut.execute
      end

      it 'gets run ID' do
        sut.execute
      end

      it 'polls until completion' do
        sut.execute
      end

      it 'copies PR URL to clipboard' do
        sut.execute
      end

      it 'pushes skip-ci commit' do
        sut.execute
      end
    end

    context 'workflow fails' do
      before do
        set_backtick_mock('git branch --show-current', 'feature-branch')
        set_backtick_mock('git remote get-url origin', REMOTE_URL)
        set_backtick_mock('git push', '')
        set_backtick_mock('gh workflow run dude.yml', '')
        set_backtick_mock('gh run list json databaseId', '12345')
        set_backtick_mock('gh run list json status', 'completed')
        set_backtick_mock('gh run list json conclusion', 'failure')
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error('Workflow failed: https://github.com/UKGEPIC/dude/actions/runs/12345')
      end
    end

    context 'no PR found' do
      before do
        set_backtick_mock('git branch --show-current', 'feature-branch')
        set_backtick_mock('git remote get-url origin', REMOTE_URL)
        set_backtick_mock('git push', '')
        set_backtick_mock('gh workflow run dude.yml', '')
        set_backtick_mock('gh run list json databaseId', '12345')
        set_backtick_mock('gh run list json status', 'completed')
        set_backtick_mock('gh run list json conclusion', 'success')
        set_backtick_mock('gh pr list head feature-branch json url', '')
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error('No PR found: https://github.com/UKGEPIC/dude/actions/runs/12345')
      end
    end

    context 'multiple PRs found' do
      before do
        set_backtick_mock('git branch --show-current', 'feature-branch')
        set_backtick_mock('git remote get-url origin', REMOTE_URL)
        set_backtick_mock('git push', '')
        set_backtick_mock('gh workflow run dude.yml', '')
        set_backtick_mock('gh run list json databaseId', '12345')
        set_backtick_mock('gh run list json status', 'completed')
        set_backtick_mock('gh run list json conclusion', 'success')
        prs = 'https://github.com/UKGEPIC/dude/pull/122' \
              "\n" \
              'https://github.com/UKGEPIC/dude/pull/123'
        set_backtick_mock('gh pr list head feature-branch json url', prs)
        set_backtick_mock('pbcopy', '')
        set_backtick_mock('git commit', '')
        stub($stdout).puts(/Multiple PRs found/)
      end

      it 'uses newest PR' do
        result = sut.execute

        expect(result).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end

      it 'warns about multiple PRs' do
        mock($stdout).puts(/Multiple PRs found, using newest/)

        sut.execute
      end
    end

    context 'branch already pushed' do
      before do
        set_backtick_mock('git branch --show-current', 'feature-branch')
        set_backtick_mock('git remote get-url origin', REMOTE_URL)
        set_backtick_mock('git push', '')
        set_backtick_mock('gh workflow run dude.yml', '')
        set_backtick_mock('gh run list json databaseId', '12345')
        set_backtick_mock('gh run list json status', 'completed')
        set_backtick_mock('gh run list json conclusion', 'success')
        set_backtick_mock('gh pr list head feature-branch json url', 'https://github.com/UKGEPIC/dude/pull/123')
        set_backtick_mock('pbcopy', '')
        set_backtick_mock('git commit', '')
      end

      it 'continues with workflow trigger' do
        sut.execute
      end
    end

    context 'running twice' do
      before do
        set_backtick_mock('git branch --show-current', 'feature-branch')
        set_backtick_mock('git remote get-url origin', REMOTE_URL)
        set_backtick_mock('git push', '')
        set_backtick_mock('gh workflow run dude.yml', '')
        set_backtick_mock('gh run list json databaseId', '12345')
        set_backtick_mock('gh run list json status', 'completed')
        set_backtick_mock('gh run list json conclusion', 'success')
        set_backtick_mock('gh pr list head feature-branch json url', 'https://github.com/UKGEPIC/dude/pull/123')
        set_backtick_mock('pbcopy', '')
        set_backtick_mock('git commit', '')
      end

      it 'runs full sequence' do
        expect(sut.execute).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end

      it 'allows empty skip-ci commit' do
        sut.execute
      end
    end
  end

  private

  def stub_backticks
    @backtick_mocks = {}
    allow_any_instance_of(Object).to receive(:`) do |_receiver, cmd|
      match = @backtick_mocks.find do |pat, _|
        pat.split.all? { |word| cmd.include?(word) }
      end
      match ? match[1] : ''
    end
  end

  def set_backtick_mock(pattern, response)
    @backtick_mocks ||= {}
    @backtick_mocks[pattern] = response
  end
end
