require_relative '../../spec_helper'
require_relative '../../../lib/dude/compact/riley'

describe Dude::Compact::Riley do
  include RR::DSL

  let(:sut) { described_class.new(silo, '/proj') }
  let(:silo) { 'frumble' }

  describe '#line' do
    before do
      stub(File).read('/proj/CLAUDE.local.md') { "notes\n- Riley: blorp\n" }
    end

    it 'returns the riley line of the silo local file' do
      expect(sut.line).to eq('- Riley: blorp')
    end

    it 'reads the fork local file for a fork name' do
      stub(File).read('/proj/CLAUDE.local.zim.md') { "- Riley: zim task\n" }
      sut = described_class.new('frumble ⑂ zim', '/proj')

      expect(sut.line).to eq('- Riley: zim task')
    end

    it 'returns nil when the local file is missing' do
      stub(File).read('/proj/CLAUDE.local.md') { raise Errno::ENOENT }

      expect(sut.line).to be_nil
    end

    it 'returns nil when the local file has no riley line' do
      stub(File).read('/proj/CLAUDE.local.md') { "notes\nnothing here" }

      expect(sut.line).to be_nil
    end
  end
end
