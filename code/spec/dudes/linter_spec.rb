require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/linter"

describe Dude::Dudes::Linter do
  include RR::DSL

  let(:files) { %w[lib/foo.rb] }

  describe '#pass?' do
    context 'ruby platform' do
      let(:sut) { described_class.new(files, :ruby) }

      it 'calls system with rubocop command' do
        expected_cmd = 'bundle exec rubocop lib/foo.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'elixir platform' do
      let(:sut) { described_class.new(files, :elixir) }

      it 'calls system with mix credo command' do
        expected_cmd = 'mix credo lib/foo.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'dotnet platform' do
      let(:sut) { described_class.new(files, :dotnet) }

      it 'calls system with dotnet format command' do
        expected_cmd = 'dotnet format --verify-no-changes > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'node platform' do
      let(:sut) { described_class.new(files, :node) }

      it 'calls system with npm run lint command' do
        expected_cmd = 'npm run lint > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'default platform is ruby' do
      let(:sut) { described_class.new(files) }

      it 'uses rubocop command' do
        expected_cmd = 'bundle exec rubocop lib/foo.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'with multiple files' do
      let(:files) { %w[lib/a.rb lib/b.rb] }
      let(:sut) { described_class.new(files, :ruby) }

      it 'joins multiple files for ruby' do
        expected_cmd = 'bundle exec rubocop lib/a.rb lib/b.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end
  end
end
