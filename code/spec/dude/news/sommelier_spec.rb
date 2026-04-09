require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/sommelier'

describe Dude::News::Sommelier do
  let(:mock_gh) { instance_double(Dude::Helpers::Gh) }
  let(:sommelier) { described_class.new(gh: mock_gh) }

  describe '#workflow_conclusion' do
    before do
      allow(mock_gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
      ).and_return('success')
    end

    it 'returns workflow conclusion from gh' do
      expect(sommelier.workflow_conclusion).to eq('success')
    end
  end

  describe '#run_url' do
    context 'when run exists' do
      before do
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('12345')
      end

      it 'returns formatted run url' do
        expect(sommelier.run_url).to eq('https://github.com/UKGEPIC/dude/actions/runs/12345')
      end
    end

    context 'when run does not exist' do
      before do
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('')
      end

      it 'returns nil' do
        expect(sommelier.run_url).to be_nil
      end
    end
  end
end
