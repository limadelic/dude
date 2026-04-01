require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/linter"

describe 'Dude::Dudes::Linter' do
  let(:described_class) { Dude::Dudes::Linter }
  let(:linter) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#pass?' do
    before do
      allow(linter).to receive(:system).and_return(true)
    end

    it 'returns true when system returns true' do
      expect(linter.pass?).to be true
    end

    it 'returns false when system returns false' do
      allow(linter).to receive(:system).and_return(false)
      expect(linter.pass?).to be false
    end
  end
end
