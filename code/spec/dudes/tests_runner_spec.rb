require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tests_runner"

describe Dude::Dudes::TestsRunner do
  include RR::DSL

  let(:sut) { described_class.new(files) }
  let(:files) { %w[spec/foo_spec.rb] }

  describe '#pass?' do
    let(:command) { 'bundle exec rspec spec/foo_spec.rb > /dev/null 2>&1' }
    let(:result) { true }

    before do
      stub(sut).system(command) { result }
    end

    it 'returns true when command succeeds' do
      expect(sut.pass?).to be true
    end

    context 'when command fails' do
      let(:result) { false }

      it 'returns false' do
        expect(sut.pass?).to be false
      end
    end

    context 'with multiple files' do
      let(:files) { %w[spec/a_spec.rb spec/b_spec.rb] }
      let(:command) {
        'bundle exec rspec spec/a_spec.rb spec/b_spec.rb > /dev/null 2>&1'
      }

      it 'joins multiple files' do
        expect(sut.pass?).to be true
      end
    end

    context 'with no files' do
      let(:files) { [] }
      let(:command) { 'bundle exec rspec  > /dev/null 2>&1' }

      it 'handles no files' do
        expect(sut.pass?).to be true
      end
    end
  end
end
