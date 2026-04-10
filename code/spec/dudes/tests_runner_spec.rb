require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tests_runner"

describe Dude::Dudes::TestsRunner do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[spec/foo_spec.rb] }

  describe '#pass?' do
    it 'returns true when system succeeds' do
      stub(sut).system { true }

      expect(sut.pass?).to be true
    end

    it 'returns false when system fails' do
      stub(sut).system { false }

      expect(sut.pass?).to be false
    end
  end
end
