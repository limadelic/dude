require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/sommelier'

describe Dude::News::Sommelier do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:gh) { Object.new }

  before do
    stub(Dude::Helpers::Gh).new { gh }
    mock(gh).run(/workflow run/) {}
    stub(gh).run(/status/) { 'completed' }
    stub(gh).run(/databaseId/) { '12345' }
    stub(gh).run(/conclusion/) { 'success' }
    stub(sut).sleep
  end

  describe '#taste' do
    it 'returns success with url' do
      expect(sut.taste('v1.2.3'))
        .to eq(
          conclusion: 'success',
          url: 'https://github.com/UKGEPIC/dude/actions/runs/12345', error: nil
        )
    end

    it 'returns failure with error logs' do
      stub(gh).run(/conclusion/) { 'failure' }
      stub(gh).run(/actions\/runs\/12345\/jobs/) { 'job123' }
      stub(gh).run(/actions\/jobs\/job123\/logs/) { 'Error: test failed' }

      expect(sut.taste('v1.2.3'))
        .to eq(
          conclusion: 'failure',
          url: 'https://github.com/UKGEPIC/dude/actions/runs/12345', error: 'Error: test failed'
        )
    end

    context 'when run is queued' do
      it 'returns result after polling through queued status' do
        calls = 0
        stub(gh).run(/status/) { (calls += 1) == 1 ? 'queued' : 'completed' }

        expect(sut.taste('v1.2.3'))
          .to eq(
            conclusion: 'success',
            url: 'https://github.com/UKGEPIC/dude/actions/runs/12345', error: nil
          )
      end
    end
  end
end
