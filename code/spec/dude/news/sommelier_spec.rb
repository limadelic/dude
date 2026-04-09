require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/sommelier'

describe Dude::News::Sommelier do
  let(:mock_gh) { instance_double(Dude::Helpers::Gh) }
  let(:sommelier) { described_class.new(gh: mock_gh) }

  before do
    allow(mock_gh).to receive(:run) do |cmd|
      case cmd
      when /workflow run/
        nil
      when /run list.*status/
        'completed'
      when /run list.*conclusion/
        conclusion_value
      when /run list.*databaseId/
        run_id_value
      when /actions\/jobs/
        job_logs
      else
        nil
      end
    end
  end

  describe '#taste' do
    context 'success path' do
      let(:conclusion_value) { 'success' }
      let(:run_id_value) { '12345' }
      let(:job_logs) { nil }

      it 'returns success conclusion with url' do
        result = sommelier.taste('v1.2.3')

        expect(result).to eq({
          conclusion: 'success',
          url: 'https://github.com/UKGEPIC/dude/actions/runs/12345',
          error: nil
        })
      end
    end

    context 'failure path' do
      let(:conclusion_value) { 'failure' }
      let(:run_id_value) { '67890' }
      let(:job_logs) { 'Error: test failed' }

      it 'returns failure conclusion with url and error' do
        result = sommelier.taste('v1.2.3')

        expect(result).to eq({
          conclusion: 'failure',
          url: 'https://github.com/UKGEPIC/dude/actions/runs/67890',
          error: 'Error: test failed'
        })
      end
    end
  end
end
