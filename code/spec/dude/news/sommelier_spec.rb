require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/sommelier'

describe Dude::News::Sommelier do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:gh) { Object.new }

  before do
    stub(Dude::Helpers::Gh).new { gh }
    stub(gh).run(/workflow run dude\.yml.*version=v1\.2\.3/)
    stub(gh).run(/status/) { 'completed' }
  end

  describe '#taste' do
    it 'returns success with url' do
      stub(gh).run(/databaseId/) { '12345' }
      stub(gh).run(/conclusion/) { 'success' }

      expect(sut.taste('v1.2.3'))
        .to eq(conclusion: 'success', url: 'https://github.com/UKGEPIC/dude/actions/runs/12345', error: nil)
    end

    it 'returns failure with error logs' do
      stub(gh).run(/databaseId/) { '67890' }
      stub(gh).run(/conclusion/) { 'failure' }
      stub(gh).run(/actions\/runs\/67890\/jobs/) { 'job123' }
      stub(gh).run(/actions\/jobs\/job123\/logs/) { 'Error: test failed' }

      expect(sut.taste('v1.2.3'))
        .to eq(conclusion: 'failure', url: 'https://github.com/UKGEPIC/dude/actions/runs/67890', error: 'Error: test failed')
    end
  end
end
