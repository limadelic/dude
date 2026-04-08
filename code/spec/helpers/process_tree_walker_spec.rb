require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/process_tree_walker'

describe Dude::Helpers::ProcessTreeWalker do
  let(:walker) { described_class.new }

  describe '#command_for' do
    it 'uses command keyword instead of cmd for cross-platform support' do
      allow(walker).to receive(:`).with('ps -o command= -p 2000')
        .and_return("dude abide\n")
      result = walker.command_for(2000)
      expect(result).to eq("dude abide")
    end
  end

  describe '#descendants_with_parents' do
    it 'returns empty arrays when no pids given' do
      descendants, parent_map = walker.descendants_with_parents([])
      expect(descendants).to eq([])
      expect(parent_map).to eq({})
    end

    it 'finds single child and parent relationship' do
      allow(walker).to receive(:`).with('pgrep -P 1000').and_return("2000\n")
      allow(walker).to receive(:`).with('pgrep -P 2000').and_return("")
      allow(walker).to receive(:command_for).and_return("dude")

      descendants, parent_map = walker.descendants_with_parents([1000])
      expect(descendants).to eq([2000])
      expect(parent_map[2000]).to eq(1000)
    end
  end
end
