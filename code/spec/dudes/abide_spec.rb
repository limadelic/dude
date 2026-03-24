require_relative '../spec_helper'
require_relative '../../lib/dudes/abide'

describe Dudes::Abide do
  subject { described_class.new }

  describe '#dead?' do
    context 'no pids found' do
      it 'is dead' do
        expect(subject.dead?([], nil, [], false)).to be true
      end
    end

    context 'pid not alive' do
      it 'is dead' do
        expect(subject.dead?([123], nil, [], false)).to be true
      end
    end

    context 'pid alive, no wip' do
      it 'is alive' do
        expect(subject.dead?([123], 123, [], false)).to be false
      end
    end

    context 'pid alive, wip with abide task' do
      it 'is alive' do
        wip = [{ 'status' => 'wip' }]
        expect(subject.dead?([123], 123, wip, true)).to be false
      end
    end

    context 'pid alive, wip without abide task' do
      it 'is dead' do
        wip = [{ 'status' => 'wip' }]
        expect(subject.dead?([123], 123, wip, false)).to be true
      end
    end

    context 'pid alive, non-wip items only' do
      it 'is alive' do
        items = [{ 'status' => 'new' }]
        expect(subject.dead?([123], 123, items, false)).to be false
      end
    end
  end
end
