require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/paperboy'

describe Dude::News::Paperboy do
  let(:mock_gh) { instance_double(Dude::Helpers::Gh) }
  let(:source) { described_class.new(gh: mock_gh) }

  describe '#latest_version' do
    before do
      allow(mock_gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
      ).and_return('v1.2.3')
    end

    it 'returns latest version from gh' do
      expect(source.latest_version).to eq('v1.2.3')
    end
  end

  describe '#workflow_conclusion' do
    before do
      allow(mock_gh).to receive(:run).with(
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
      ).and_return('success')
    end

    it 'returns workflow conclusion from gh' do
      expect(source.workflow_conclusion).to eq('success')
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
        expect(source.run_url).to eq('https://github.com/UKGEPIC/dude/actions/runs/12345')
      end
    end

    context 'when run does not exist' do
      before do
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('')
      end

      it 'returns nil' do
        expect(source.run_url).to be_nil
      end
    end
  end

  describe '#releases' do
    before do
      allow(mock_gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 3 --json tagName -q '.[].tagName'"
      ).and_return("v1.0.0\nv0.9.0\nv0.8.0")
    end

    it 'returns releases array with given limit' do
      expect(source.releases(3)).to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end
  end
end
