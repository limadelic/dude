require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tests_runner"

describe 'Dude::Dudes::TestsRunner' do
  let(:described_class) { Dude::Dudes::TestsRunner }
  let(:runner) { described_class.new(files) }
  let(:files) { %w[spec/foo_spec.rb] }

  describe '#pass?' do
    before do
      allow(runner).to receive(:system).and_return(true)
    end

    it 'returns true when system returns true' do
      expect(runner.pass?).to be true
    end

    it 'returns false when system returns false' do
      allow(runner).to receive(:system).and_return(false)
      expect(runner.pass?).to be false
    end
  end
end
