require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tests_runner"

describe Dude::Dudes::TestsRunner do
  include RR::DSL

  let(:files) { %w[spec/foo_spec.rb] }

  describe '#pass?' do
    context 'ruby platform' do
      let(:sut) { described_class.new(files, :ruby) }

      it 'calls system with rspec command' do
        expected_cmd = 'bundle exec rspec spec/foo_spec.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'elixir platform' do
      let(:sut) { described_class.new(files, :elixir) }

      it 'calls system with mix test command' do
        expected_cmd = 'mix test spec/foo_spec.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'dotnet platform' do
      let(:sut) { described_class.new(files, :dotnet) }

      it 'calls system with dotnet test command' do
        expected_cmd = 'dotnet test > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'node platform' do
      let(:sut) { described_class.new(files, :node) }

      it 'calls system with npm test command' do
        expected_cmd = 'npm test > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'default platform is ruby' do
      let(:sut) { described_class.new(files) }

      it 'uses rspec command' do
        expected_cmd = 'bundle exec rspec spec/foo_spec.rb > /dev/null 2>&1'
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end

    context 'with multiple files' do
      let(:files) { %w[spec/a_spec.rb spec/b_spec.rb] }
      let(:sut) { described_class.new(files, :ruby) }
      let(:expected_cmd) do
        'bundle exec rspec spec/a_spec.rb spec/b_spec.rb > /dev/null 2>&1'
      end

      it 'joins multiple files for ruby' do
        stub(sut).system(expected_cmd) { true }

        expect(sut.pass?).to eq true
      end
    end
  end
end
