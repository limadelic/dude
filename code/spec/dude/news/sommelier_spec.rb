require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/sommelier'

describe Dude::News::Sommelier do
  let(:gh) { instance_double(Dude::Helpers::Gh) }
  let(:sut) { described_class.new }

  before { allow(Dude::Helpers::Gh).to receive(:new).and_return(gh) }

  describe '#taste' do
    it 'triggers workflow and returns success with url' do
      expect(gh).to receive(:run).with(
        "workflow run dude.yml -R UKGEPIC/dude -f prompt=\"1 + 1\" -f version=v1.2.3 -f timeout=5"
      )
      expect(gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --limit 1 --json status -q '.[0].status'"
      ).and_return('completed')
      expect(gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
      ).and_return('12345')
      expect(gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
      ).and_return('success')

      result = sut.taste('v1.2.3')

      expect(result).to eq({
        conclusion: 'success',
        url: 'https://github.com/UKGEPIC/dude/actions/runs/12345',
        error: nil
      })
    end

    it 'returns failure with error logs' do
      expect(gh).to receive(:run).with(
        "workflow run dude.yml -R UKGEPIC/dude -f prompt=\"1 + 1\" -f version=v1.2.3 -f timeout=5"
      )
      expect(gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --limit 1 --json status -q '.[0].status'"
      ).and_return('completed')
      expect(gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
      ).and_return('67890').twice
      expect(gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
      ).and_return('failure')
      expect(gh).to receive(:run).with(
        "api repos/UKGEPIC/dude/actions/runs/67890/jobs --jq '.jobs[0].id'"
      ).and_return('job123')
      expect(gh).to receive(:run).with(
        "api repos/UKGEPIC/dude/actions/jobs/job123/logs"
      ).and_return('Error: test failed')

      result = sut.taste('v1.2.3')

      expect(result).to eq({
        conclusion: 'failure',
        url: 'https://github.com/UKGEPIC/dude/actions/runs/67890',
        error: 'Error: test failed'
      })
    end
  end
end
