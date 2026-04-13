require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/process_tree_walker'

describe Dude::Helpers::ProcessTreeWalker do
  include RR::DSL

  let(:sut) { described_class.new }

  describe '#command_for' do
    it 'uses command keyword instead of cmd for cross-platform support' do
      stub(sut).`('ps -o command= -p 2000') { "dude abide\n" }

      expect(sut.command_for(2000)).to eq("dude abide")
    end
  end

  describe '#descendants_with_parents' do
    it 'returns empty arrays when no pids given' do
      descendants, parent_map = sut.descendants_with_parents([])

      expect(descendants).to eq([])
      expect(parent_map).to eq({})
    end

    it 'finds single child and parent relationship' do
      stub(sut).`('pgrep -P 1000') { "2000\n" }
      stub(sut).`('pgrep -P 2000') { "" }

      descendants, parent_map = sut.descendants_with_parents([1000])

      expect(descendants).to eq([2000])
      expect(parent_map[2000]).to eq(1000)
    end
  end
end
