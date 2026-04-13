require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tests_runner"

describe Dude::Dudes::TestsRunner do
  include RR::DSL

  let(:files) { %w[spec/foo_spec.rb] }

  describe '#pass?' do
    let(:sut) { described_class.new(files) }

    it 'returns true when command succeeds' do
      any_instance_of(Dude::Dudes::TestsRunner) do |obj|
        mock(obj).system('bundle exec rspec spec/foo_spec.rb > /dev/null 2>&1') { true }
      end

      expect(sut.pass?).to be true
    end

    it 'returns false when command fails' do
      any_instance_of(Dude::Dudes::TestsRunner) do |obj|
        mock(obj).system('bundle exec rspec spec/foo_spec.rb > /dev/null 2>&1') { false }
      end

      expect(sut.pass?).to be false
    end

    it 'executes rspec with all files' do
      any_instance_of(Dude::Dudes::TestsRunner) do |obj|
        mock(obj).system('bundle exec rspec spec/foo_spec.rb > /dev/null 2>&1') { true }
      end

      sut.pass?
    end

    it 'joins multiple files' do
      sut = described_class.new(%w[spec/a_spec.rb spec/b_spec.rb])
      any_instance_of(Dude::Dudes::TestsRunner) do |obj|
        mock(obj).system('bundle exec rspec spec/a_spec.rb spec/b_spec.rb > /dev/null 2>&1') { true }
      end

      sut.pass?
    end

    it 'handles no files' do
      sut = described_class.new([])
      any_instance_of(Dude::Dudes::TestsRunner) do |obj|
        mock(obj).system('bundle exec rspec  > /dev/null 2>&1') { true }
      end

      sut.pass?
    end
  end
end
