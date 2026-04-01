require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/pub'

describe Dude::Dudes::Pub do
  let(:target) { '/proj/.claude' }
  let(:global_dudes_dir) { File.expand_path('~/.claude/dudes') }

  def build(overrides = {})
    defaults = { target: target }
    described_class.new(**defaults.merge(overrides))
  end

  describe '#pub' do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      allow(File).to receive(:symlink?)
      allow(File).to receive(:symlink)
      allow(File).to receive(:delete)
    end

    it 'creates dudes directory and initializes inbox' do
      pub = build(target: '/proj/.claude')
      result = pub.pub('/proj/.claude', 'myicon')

      expect(FileUtils).to have_received(:mkdir_p).with('/proj/.claude/dudes')
    end

    it 'writes status.json with name' do
      pub = build(target: '/proj/.claude')
      allow(JSON).to receive(:load_file).and_return({})
      allow(File).to receive(:write)

      pub.pub('/proj/.claude', 'myicon')

      # Verify write was called for status.json
      expect(File).to have_received(:write).at_least(:once)
    end

    it 'creates symlink in global dudes directory' do
      pub = build(target: '/proj/.claude')
      allow(File).to receive(:symlink?)
      allow(File).to receive(:write)
      allow(JSON).to receive(:load_file).and_return({})

      pub.pub('/proj/.claude', 'myicon')

      expect(File).to have_received(:symlink).with('/proj/.claude/', anything)
    end

    it 'returns the icon name' do
      pub = build(target: '/proj/.claude')
      allow(File).to receive(:write)
      allow(JSON).to receive(:load_file).and_return({})
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:symlink)
      allow(File).to receive(:symlink?)

      result = pub.pub('/proj/.claude', 'myicon')

      expect(result).to eq('myicon')
    end

    it 'uses target name as default icon' do
      pub = build(target: '/proj/.claude')
      allow(File).to receive(:write)
      allow(JSON).to receive(:load_file).and_return({})
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:symlink)
      allow(File).to receive(:symlink?)

      result = pub.pub('/proj/.claude', nil)

      expect(result).to eq('/proj/.claude')
    end
  end

  describe '#unpub' do
    before do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:children).and_return([])
      allow(File).to receive(:symlink?).and_return(false)
      allow(File).to receive(:readlink)
      allow(FileUtils).to receive(:rm_rf)
      allow(File).to receive(:delete)
    end

    it 'removes dudes directory when global dir exists' do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:children).and_return([])

      pub = build
      pub.unpub('/proj/.claude')

      expect(Dir).to have_received(:exist?)
    end

    it 'does nothing when global dir does not exist' do
      allow(Dir).to receive(:exist?).and_return(false)

      pub = build
      pub.unpub('/proj/.claude')

      expect(Dir).to have_received(:exist?)
    end

    it 'removes symlinks and their targets' do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:children).and_return(['rec', 'smith'])
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/proj/.claude/')

      pub = build
      pub.unpub('/proj/.claude')

      expect(FileUtils).to have_received(:rm_rf).at_least(:once)
    end
  end

  describe '#sub' do
    before do
      pub_hash = { name: 'dude', path: '/home/.claude/dudes' }
      allow(Dude::Dudes::PubFinder).to(
        receive(:find_nearest_pub).and_return(pub_hash)
      )
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      allow(JSON).to receive(:load_file).and_return({})
      allow(File).to receive(:symlink)
      allow(File).to receive(:symlink?)
      allow(File).to receive(:exist?).and_return(false)
      allow(Dir).to receive(:exist?).and_return(false)
    end

    it 'calls find_nearest_pub to find parent pub' do
      pub = build(target: '/code/.claude')
      pub.sub('/code', 'dev')

      finder = Dude::Dudes::PubFinder
      expect(finder).to have_received(:find_nearest_pub).with('/code')
    end

    it 'creates dudes/dudes directory inside parent pub' do
      pub = build(target: '/code/.claude')
      pub.sub('/code', 'dev')

      path = '/home/.claude/dudes/dudes'
      expect(FileUtils).to have_received(:mkdir_p).with(path)
    end

    it 'initializes inbox in the sub dudes directory' do
      pub = build(target: '/code/.claude')
      pub.sub('/code', 'dev')

      expect(File).to have_received(:write).with(
        '/home/.claude/dudes/dudes/inbox.json', '[]'
      )
    end

    it 'writes status with underscore-prefixed name in JSON' do
      pub = build(target: '/code/.claude')
      pub.sub('/code', 'dev')

      expect(File).to have_received(:write).with(
        '/home/.claude/dudes/dudes/status.json',
        include('"name":"dude_dev"')
      )
    end

    it 'creates symlink pointing to sub target' do
      allow(Dir).to receive(:exist?) { |path| path == '/code/.claude' }
      pub = build(target: '/code/.claude')
      pub.sub('/code', 'dev')

      expect(File).to have_received(:symlink).with('/code/.claude/', anything)
    end

    it 'symlink is created in parent pub dudes/dudes directory' do
      allow(Dir).to receive(:exist?) { |path| path == '/code/.claude' }
      pub = build(target: '/code/.claude')
      pub.sub('/code', 'dev')

      expect(File).to have_received(:symlink).with(
        '/code/.claude/',
        File.join('/home/.claude/dudes/dudes', 'dude_dev')
      )
    end

    it 'returns underscore-prefixed full name' do
      pub = build(target: '/code/.claude')
      result = pub.sub('/code', 'dev')

      expect(result).to eq('dude_dev')
    end

    it 'uses basename of target as name when name is nil' do
      pub = build(target: '/some/path/code/.claude')
      result = pub.sub('/some/path/code', nil)

      expect(result).to eq('dude_code')
    end
  end

  describe '#claude_dir' do
    it 'returns the path itself when it IS a .claude directory' do
      pub = build
      result = pub.send(:claude_dir, '/home/user/.claude')
      expect(result).to eq('/home/user/.claude')
    end

    it 'returns .claude subdirectory when it exists' do
      pub = build
      path = '/projects/myapp/.claude'
      allow(Dir).to receive(:exist?).with(path).and_return(true)
      result = pub.send(:claude_dir, '/projects/myapp')
      expect(result).to eq(path)
    end

    it 'returns the path itself when .claude subdirectory does not exist' do
      pub = build
      allow(Dir).to receive(:exist?).and_return(false)
      result = pub.send(:claude_dir, '/some/path')
      expect(result).to eq('/some/path')
    end

    it 'avoids nested .claude/.claude even if it exists' do
      pub = build
      allow(Dir).to receive(:exist?).and_return(true)
      result = pub.send(:claude_dir, '/home/user/.claude')
      expect(result).to eq('/home/user/.claude')
      expect(result).not_to eq('/home/user/.claude/.claude')
    end
  end
end
