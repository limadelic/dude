require_relative '../../spec_helper'
require_relative '../../../lib/dude/compact/riley'

describe Dude::Compact::Riley do
  include RR::DSL

  let(:sut) { described_class.new(silo, cwd) }
  let(:silo) { 'frumble' }
  let(:cwd) { '/proj' }
  let(:path) { "#{cwd}/CLAUDE.local.md" }
  let(:file) { "notes\n- Riley: blorp\n" }

  describe '#line' do
    before do
      stub(File).read(path) { file }
    end

    it 'returns the riley line of the silo local file' do
      expect(sut.line).to eq('- Riley: blorp')
    end

    context 'when the silo is a fork' do
      let(:silo) { 'frumble ⑂ zim' }
      let(:path) { "#{cwd}/CLAUDE.local.zim.md" }
      let(:file) { "- Riley: zim task\n" }

      it 'returns the riley line of the fork local file' do
        expect(sut.line).to eq('- Riley: zim task')
      end
    end

    context 'when the riley line has trailing spaces' do
      let(:file) { "- Riley: blorp   \n" }

      it 'returns the line stripped' do
        expect(sut.line).to eq('- Riley: blorp')
      end
    end

    context 'when riley is not at the start of a line' do
      let(:file) { "notes - Riley: x\n" }

      it 'returns nil' do
        expect(sut.line).to be_nil
      end
    end

    context 'when the riley tag is lowercase' do
      let(:file) { "- riley: blorp\n" }

      it 'returns the line' do
        expect(sut.line).to eq('- riley: blorp')
      end
    end

    context 'when the local file is missing' do
      let(:file) { raise Errno::ENOENT }

      it 'returns nil' do
        expect(sut.line).to be_nil
      end
    end

    context 'when the local file has no riley line' do
      let(:file) { "notes\nnothing here" }

      it 'returns nil' do
        expect(sut.line).to be_nil
      end
    end
  end
end
