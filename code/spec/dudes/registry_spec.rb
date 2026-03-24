require_relative '../spec_helper'
require_relative '../../lib/dudes/registry'

describe Dudes::Registry do
  let(:fs) { instance_double(Helpers::FS, dir_exist?: true) }
  let(:cwd) { File.expand_path('~/.claude') }

  def registry(cwd_override = cwd, ctx = 25)
    described_class.new(fs, cwd_override, ctx)
  end

  def dude(name, target, opts = {})
    {
      name: name,
      icon: opts[:icon] || '🎳',
      target: target,
      status: opts[:status] || { 'context' => opts[:context] || 25 },
      inbox: opts[:inbox] || [],
      abide_dead: opts[:abide_dead] || false
    }
  end

  describe '#load' do
    it 'builds dude records with icon and name' do
      result = registry.load([dude('dude', "#{cwd}")])
      expect(result.first).to include(name: 'dude', icon: '🎳')
    end

    it 'marks current dude' do
      dudes = [
        dude('dude', cwd),
        dude('rec', '/proj/.claude', icon: '🔴')
      ]
      result = registry.load(dudes)
      expect(result.find { |d| d[:name] == 'dude' }[:current]).to be true
      expect(result.find { |d| d[:name] == 'rec' }[:current]).to be false
    end

    it 'marks current from project cwd' do
      result = registry('/proj').load([
        dude('dude', cwd),
        dude('rec', '/proj/.claude', icon: '🔴')
      ])
      expect(result.find { |d| d[:name] == 'rec' }[:current]).to be true
    end

    it 'counts messages from inbox' do
      result = registry.load([dude('rec', '/proj/.claude', inbox: [{}, {}, {}])])
      expect(result.first[:messages]).to eq(3)
    end

    it 'uses live context for current dude' do
      result = registry(cwd, 75).load([dude('dude', cwd, context: 10)])
      expect(result.first[:context]).to eq(75)
    end

    it 'uses stored context for non-current dude' do
      result = registry.load([dude('rec', '/proj/.claude', context: 60)])
      expect(result.first[:context]).to eq(60)
    end

    it 'defaults context to 0 when missing' do
      result = registry.load([dude('rec', '/proj/.claude', status: {})])
      expect(result.first[:context]).to eq(0)
    end

    it 'preserves abide_dead flag' do
      result = registry.load([dude('rec', '/proj/.claude', abide_dead: true)])
      expect(result.first[:abide_dead]).to be true
    end

    it 'resolves claude dir without .claude suffix' do
      allow(fs).to receive(:dir_exist?).and_return(false)
      result = registry('/proj').load([dude('rec', '/proj', icon: '🔴')])
      expect(result.first[:current]).to be true
    end
  end
end
