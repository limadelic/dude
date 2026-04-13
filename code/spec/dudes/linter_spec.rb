require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/linter"

describe Dude::Dudes::Linter do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[lib/foo.rb] }

  describe '#pass?' do
    before { stub(sut).system { true } }

    it 'returns true when rubocop passes' do
      expect(sut.pass?).to be true
    end

    it 'returns false when rubocop fails' do
      stub(sut).system { false }

      expect(sut.pass?).to be false
    end
  end
end
