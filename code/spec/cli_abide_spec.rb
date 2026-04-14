require_relative './spec_helper'
require_relative '../lib/dude/helpers/cli'

describe Dude::Helpers::Cli do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:dudes) { Object.new }
  let(:dude) { Object.new }

  before do
    stub(Dude::Dudes::Dudes).new { dudes }
    stub(dudes).current { dude }
  end

  describe '#abide' do
    it 'abides when dude is running' do
      stub(dude).abide { '"result message"' }

      output = capture_output { sut.abide }
      expect(output).to include('result message')
    end
  end

  describe '#sub' do
    it 'registers as a sub dude with provided name' do
      stub(dude).sub('myapp') { 'myapp' }

      output = capture_output { sut.sub('myapp') }
      expect(output).to include('myapp')
    end

    it 'registers as a sub dude with default name when not provided' do
      stub(dude).sub(nil) { 'subfolder' }

      output = capture_output { sut.sub }
      expect(output).to include('subfolder')
    end

    it 'raises error when no dude is running' do
      stub(dudes).current { nil }

      expect { sut.sub('myapp') }.to raise_error('No dude running')
    end
  end
end
