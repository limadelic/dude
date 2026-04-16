require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/alley_pr"
require_relative "../../lib/dude/helpers/wait"

describe Dude::Dudes::AlleyPr do
  include RR::DSL

  REMOTE_URL = 'git@github.com:UKGEPIC/dude.git'
  WORKFLOW_MOCKS = {
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
    stub_backticks
    stub(Dude::Helpers::Wait).new { wait }
    stub(wait).until { |&block| block.call }
  end

  describe '#execute' do
    context 'on main branch' do
      it 'raises error' do
        set_backtick_mock('git branch --show-current', 'main')

        expect { sut.execute }.to raise_error('Cannot run on main branch')
      end
    end

    context 'happy path' do
      before { setup_happy_path }

      it 'executes full sequence and returns PR URL' do
        result = sut.execute

        expect(result).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end
    end

    context 'workflow fails' do
      before do
        setup_workflow_base
        set_backtick_mock('gh run view 12345 json conclusion', 'failure')
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error(
          'Workflow failed: https://github.com/UKGEPIC/dude/actions/runs/12345'
        )
      end
    end

    context 'no PR found' do
      before do
        setup_workflow_base
        set_backtick_mock('gh pr list head feature-branch json url', '')
      end

      it 'raises error with run URL' do
        expect { sut.execute }.to raise_error(
          'No PR found: https://github.com/UKGEPIC/dude/actions/runs/12345'
        )
      end
    end

    context 'multiple PRs found' do
      before { setup_multiple_prs }

      it 'uses newest PR and warns' do
        mock($stdout).puts(/Multiple PRs found, using newest/)

        result = sut.execute

        expect(result).to eq 'https://github.com/UKGEPIC/dude/pull/123'
      end
    end
  end

  private

  def stub_backticks
    @backtick_mocks = {}
    allow_any_instance_of(Object).to receive(:`) { |_, cmd| find_mock(cmd) }
  end

  def find_mock(cmd)
    match = @backtick_mocks.find do |pat, _|
      pat.split.all? { |word| cmd.include?(word) }
    end
    match&.last || ''
  end

  def set_backtick_mock(pattern, response)
    @backtick_mocks ||= {}
    @backtick_mocks[pattern] = response
  end

  def setup_workflow_base
    WORKFLOW_MOCKS.each { |pat, res| set_backtick_mock(pat, res) }
  end

  def setup_happy_path
    setup_workflow_base
    pr_url = 'https://github.com/UKGEPIC/dude/pull/123'
    set_backtick_mock('gh pr list head feature-branch json url', pr_url)
    set_backtick_mock('pbcopy', '')
    set_backtick_mock('git commit', '')
  end

  def setup_multiple_prs
    setup_happy_path
    prs = "https://github.com/UKGEPIC/dude/pull/122\n" \
          "https://github.com/UKGEPIC/dude/pull/123"
    set_backtick_mock('gh pr list head feature-branch json url', prs)
  end
end
