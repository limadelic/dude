require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/alley_pr"
require_relative "../../lib/dude/helpers/gh"
require_relative "../../lib/dude/helpers/wait"

describe Dude::Dudes::AlleyPr do
  include RR::DSL

  RUN_LIST_CMD = 'run list --workflow=dude.yml --limit 1 --json databaseId ' \
                 "-q '.[0].databaseId'".freeze
  PR_LIST_CMD = "pr list --head feature-branch --state open --json url " \
                "-q '.[].url'".freeze
  REMOTE_URL = 'git@github.com:UKGEPIC/dude.git'

  let(:sut) { described_class.new }
  let(:gh) { Object.new }
  let(:wait) { Object.new }

  before do
    stub(Dude::Helpers::Gh).create { gh }
    stub(Dude::Helpers::Wait).new { wait }
  end

  describe '#execute' do
    context 'on main branch' do
      it 'raises error' do
        stub(sut).run_command('git branch --show-current') { 'main' }

        expect { sut.execute }.to raise_error('Cannot run on main branch')
      end
    end

    context 'happy path' do
      before do
        stub(sut).run_command('git branch --show-current') { 'feature-branch' }
        stub(sut).run_command('git remote get-url origin') { REMOTE_URL }
        stub(sut).run_command(/git push/) { '' }
        stub(gh).run('workflow run dude.yml --ref feature-branch') { '' }
        stub(gh).run(RUN_LIST_CMD) { '12345' }
        stub(wait).until { block_given? ? true : false }
        stub(gh).run('run view 12345 --json status -q .status') { 'completed' }
        stub(gh).run('run view 12345 --json conclusion -q .conclusion') do
          'success'
        end
        stub(gh).run(PR_LIST_CMD) do
          'https://github.com/UKGEPIC/dude/pull/123'
        end
        stub(sut).run_command(/pbcopy/) { '' }
        stub(sut).run_command(/git commit --allow-empty/) { '' }
      end

      it 'executes full sequence and returns PR URL' do
        result = sut.execute

        expect(result).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end

      it 'pushes branch' do
        mock(sut).run_command(/git push/)

        sut.execute
      end

      it 'triggers workflow' do
        mock(gh).run('workflow run dude.yml --ref feature-branch')

        sut.execute
      end

      it 'gets run ID' do
        mock(gh).run(RUN_LIST_CMD) { '12345' }

        sut.execute
      end

      it 'polls until completion' do
        mock(wait).until { true }

        sut.execute
      end

      it 'copies PR URL to clipboard' do
        cmd = 'echo https://github.com/UKGEPIC/dude/pull/123 | pbcopy'
        mock(sut).run_command(cmd)

        sut.execute
      end

      it 'pushes skip-ci commit' do
        cmd = 'git commit --allow-empty -m "[skip ci]" && git push'
        mock(sut).run_command(cmd)

        sut.execute
      end
    end

    context 'workflow fails' do
      before do
        stub(sut).run_command('git branch --show-current') { 'feature-branch' }
        stub(sut).run_command('git remote get-url origin') { REMOTE_URL }
        stub(sut).run_command(/git push/) { '' }
        stub(gh).run('workflow run dude.yml --ref feature-branch') { '' }
        stub(gh).run(RUN_LIST_CMD) { '12345' }
        stub(wait).until { block_given? ? true : false }
        stub(gh).run('run view 12345 --json status -q .status') { 'completed' }
        stub(gh).run('run view 12345 --json conclusion -q .conclusion') do
          'failure'
        end
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error('Workflow failed: https://github.com/UKGEPIC/dude/actions/runs/12345')
      end
    end

    context 'no PR found' do
      before do
        stub(sut).run_command('git branch --show-current') { 'feature-branch' }
        stub(sut).run_command('git remote get-url origin') { REMOTE_URL }
        stub(sut).run_command(/git push/) { '' }
        stub(gh).run('workflow run dude.yml --ref feature-branch') { '' }
        stub(gh).run(RUN_LIST_CMD) { '12345' }
        stub(wait).until { block_given? ? true : false }
        stub(gh).run('run view 12345 --json status -q .status') { 'completed' }
        stub(gh).run('run view 12345 --json conclusion -q .conclusion') do
          'success'
        end
        stub(gh).run(PR_LIST_CMD) { '' }
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error('No PR found: https://github.com/UKGEPIC/dude/actions/runs/12345')
      end
    end

    context 'multiple PRs found' do
      before do
        stub(sut).run_command('git branch --show-current') { 'feature-branch' }
        stub(sut).run_command('git remote get-url origin') { REMOTE_URL }
        stub(sut).run_command(/git push/) { '' }
        stub(gh).run('workflow run dude.yml --ref feature-branch') { '' }
        stub(gh).run(RUN_LIST_CMD) { '12345' }
        stub(wait).until { block_given? ? true : false }
        stub(gh).run('run view 12345 --json status -q .status') { 'completed' }
        stub(gh).run('run view 12345 --json conclusion -q .conclusion') do
          'success'
        end
        prs = 'https://github.com/UKGEPIC/dude/pull/122' \
              "\n" \
              'https://github.com/UKGEPIC/dude/pull/123'
        stub(gh).run(PR_LIST_CMD) { prs }
        stub(sut).run_command(/pbcopy/) { '' }
        stub(sut).run_command(/git commit --allow-empty/) { '' }
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
        stub(sut).run_command('git branch --show-current') { 'feature-branch' }
        stub(sut).run_command('git remote get-url origin') { REMOTE_URL }
        stub(sut).run_command(/git push/) { '' }
        stub(gh).run('workflow run dude.yml --ref feature-branch') { '' }
        stub(gh).run(RUN_LIST_CMD) { '12345' }
        stub(wait).until { block_given? ? true : false }
        stub(gh).run('run view 12345 --json status -q .status') { 'completed' }
        stub(gh).run('run view 12345 --json conclusion -q .conclusion') do
          'success'
        end
        stub(gh).run(PR_LIST_CMD) do
          'https://github.com/UKGEPIC/dude/pull/123'
        end
        stub(sut).run_command(/pbcopy/) { '' }
        stub(sut).run_command(/git commit --allow-empty/) { '' }
      end

      it 'continues with workflow trigger' do
        mock(gh).run('workflow run dude.yml --ref feature-branch')

        sut.execute
      end
    end

    context 'running twice' do
      before do
        stub(sut).run_command('git branch --show-current') { 'feature-branch' }
        stub(sut).run_command('git remote get-url origin') { REMOTE_URL }
        stub(sut).run_command(/git push/) { '' }
        stub(gh).run('workflow run dude.yml --ref feature-branch') { '' }
        stub(gh).run(RUN_LIST_CMD) { '12345' }
        stub(wait).until { block_given? ? true : false }
        stub(gh).run('run view 12345 --json status -q .status') { 'completed' }
        stub(gh).run('run view 12345 --json conclusion -q .conclusion') do
          'success'
        end
        stub(gh).run(PR_LIST_CMD) do
          'https://github.com/UKGEPIC/dude/pull/123'
        end
        stub(sut).run_command(/pbcopy/) { '' }
        stub(sut).run_command(/git commit --allow-empty/) { '' }
      end

      it 'runs full sequence' do
        expect(sut.execute).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end

      it 'allows empty skip-ci commit' do
        cmd = 'git commit --allow-empty -m "[skip ci]" && git push'
        mock(sut).run_command(cmd)

        sut.execute
      end
    end
  end
end
