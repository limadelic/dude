require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/pub_finder"

describe Dude::Dudes::PubFinder do
  describe '.find_nearest_pub' do
    let(:global_dudes_dir) { File.expand_path('~/.claude/dudes') }

    it 'returns pub name and dudes dir for nearest matching pub walking up' do
      start_path = '/proj/src/feature'
      proj_claude = '/proj/.claude'
      dudes_dir = File.join(proj_claude, 'dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(proj_claude).and_return(true)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.with(proj_claude).and_return('myproj')

      result = described_class.find_nearest_pub(start_path)

      expect(result).to eq({ name: 'myproj', path: dudes_dir })
    end

    it 'walks up directories to find matching pub' do
      start_path = '/a/b/c/d/e/f'
      abc_claude = '/a/b/c/.claude'
      dudes_dir = File.join(abc_claude, 'dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(abc_claude).and_return(true)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.with(abc_claude).and_return('abc')

      result = described_class.find_nearest_pub(start_path)

      expect(result).to eq({ name: 'abc', path: dudes_dir })
    end

    it 'returns global pub when no matching pub found walking up' do
      start_path = '/proj/src/file.rb'
      global_dudes = File.expand_path('~/.claude/dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.and_return(nil)

      result = described_class.find_nearest_pub(start_path)

      expect(result).to eq({ name: 'global', path: global_dudes })
    end

    it 'prefers nearest pub over distant one' do
      start_path = '/a/b/c'
      b_claude = '/a/b/.claude'
      b_dudes = File.join(b_claude, 'dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(b_claude).and_return(true)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.with(b_claude).and_return('b')

      result = described_class.find_nearest_pub(start_path)

      expect(result).to eq({ name: 'b', path: b_dudes })
    end

    it 'returns global pub when start_path does not exist' do
      start_path = '/nonexistent/path'
      global_dudes = File.expand_path('~/.claude/dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(false)

      result = described_class.find_nearest_pub(start_path)

      expect(result).to eq({ name: 'global', path: global_dudes })
    end

    it 'returns global pub when start_path IS ~/.claude itself' do
      home_claude = File.expand_path('~/.claude')
      global_dudes = File.expand_path('~/.claude/dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(home_claude).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      nested_claude = File.join(home_claude, '.claude')
      allow(Dir).to receive(:exist?).with(nested_claude).and_return(false)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.and_return(nil)

      result = described_class.find_nearest_pub(home_claude)

      expect(result).to eq({ name: 'global', path: global_dudes })
    end

    it 'normalizes trailing slashes on start_path' do
      start_path = '/proj/src/feature/'
      proj_claude = '/proj/.claude'
      dudes_dir = File.join(proj_claude, 'dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/proj/src/feature').and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(proj_claude).and_return(true)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.with(proj_claude).and_return('myproj')

      result = described_class.find_nearest_pub(start_path)

      expect(result).to eq({ name: 'myproj', path: dudes_dir })
    end
  end

  describe '.find_pub_walking_up' do
    it 'returns pub name and dudes dir when found' do
      start_path = '/proj/src'
      proj_claude = '/proj/.claude'
      dudes_dir = File.join(proj_claude, 'dudes')

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(proj_claude).and_return(true)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.with(proj_claude).and_return('myproj')

      result = described_class.find_pub_walking_up(start_path)

      expect(result).to eq({ name: 'myproj', path: dudes_dir })
    end

    it 'returns nil when no pub found' do
      start_path = '/proj/src'

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).and_return(false)
      stub = allow(described_class).to receive(:find_pub_name_for_target)
      stub.and_return(nil)

      result = described_class.find_pub_walking_up(start_path)

      expect(result).to be_nil
    end

    it 'returns nil when start_path does not exist' do
      start_path = '/nonexistent'

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(start_path).and_return(false)

      result = described_class.find_pub_walking_up(start_path)

      expect(result).to be_nil
    end
  end

  describe '.find_pub_name_for_target' do
    it 'returns pub name when symlink matches target' do
      target = '/proj/.claude'
      global_dir = File.expand_path('~/.claude')

      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:children).and_return(['myproj'])
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/proj/.claude/')

      result = described_class.find_pub_name_for_target(target)

      expect(result).to eq('myproj')
    end

    it 'returns nil when no matching symlink found' do
      target = '/proj/.claude'
      global_dir = File.expand_path('~/.claude')

      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:children).and_return(['other'])
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/other/path/')

      result = described_class.find_pub_name_for_target(target)

      expect(result).to be_nil
    end

    it 'returns nil when global dir does not exist' do
      target = '/proj/.claude'
      global_dir = File.expand_path('~/.claude')

      allow(Dir).to receive(:exist?).and_return(false)

      result = described_class.find_pub_name_for_target(target)

      expect(result).to be_nil
    end

    it 'normalizes trailing slashes when comparing targets' do
      target = '/proj/.claude'
      global_dir = File.expand_path('~/.claude')

      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:children).and_return(['myproj'])
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/proj/.claude/')

      result = described_class.find_pub_name_for_target(target)

      expect(result).to eq('myproj')
    end
  end
end
