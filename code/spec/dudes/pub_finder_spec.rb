require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/pub_finder"

describe Dude::Dudes::PubFinder do
  include RR::DSL

  describe '.find_nearest_pub' do
    it 'finds pub in parent directory' do
      start_path = '/proj/src/feature'
      proj_claude = '/proj/.claude'
      dudes_dir = File.join(proj_claude, 'dudes')

      stub(File).exist?(start_path) { true }
      stub(Dir).exist?(/\.claude/) { |path|
        path == proj_claude
      }
      stub(described_class).find_pub_name_for_target(proj_claude) { 'myproj' }

      expect(described_class.find_nearest_pub(start_path))
        .to eq({ name: 'myproj', path: dudes_dir })
    end

    it 'walks up multiple directory levels' do
      start_path = '/a/b/c/d/e/f'
      abc_claude = '/a/b/c/.claude'
      dudes_dir = File.join(abc_claude, 'dudes')

      stub(File).exist?(start_path) { true }
      stub(Dir).exist?(/\.claude/) { |path|
        path == abc_claude
      }
      stub(described_class).find_pub_name_for_target(abc_claude) { 'abc' }

      expect(described_class.find_nearest_pub(start_path))
        .to eq({ name: 'abc', path: dudes_dir })
    end

    it 'returns global pub when walking up finds nothing' do
      start_path = '/proj/src/file.rb'
      global_dudes = File.expand_path('~/.claude/dudes')

      stub(File).exist?(start_path) { true }
      stub(Dir).exist?(/\.claude/) { false }
      stub(described_class).find_pub_name_for_target { nil }

      expect(described_class.find_nearest_pub(start_path))
        .to eq({ name: 'global', path: global_dudes })
    end

    it 'chooses nearest pub over distant' do
      start_path = '/a/b/c'
      b_claude = '/a/b/.claude'
      b_dudes = File.join(b_claude, 'dudes')

      stub(File).exist?(start_path) { true }
      stub(Dir).exist?(/\.claude/) { |path|
        path == b_claude
      }
      stub(described_class).find_pub_name_for_target(b_claude) { 'b' }

      expect(described_class.find_nearest_pub(start_path))
        .to eq({ name: 'b', path: b_dudes })
    end

    it 'returns global pub when start path does not exist' do
      start_path = '/nonexistent/path'
      global_dudes = File.expand_path('~/.claude/dudes')

      stub(File).exist?(start_path) { false }

      expect(described_class.find_nearest_pub(start_path))
        .to eq({ name: 'global', path: global_dudes })
    end

    it 'returns global pub for ~/.claude itself' do
      home_claude = File.expand_path('~/.claude')
      global_dudes = File.expand_path('~/.claude/dudes')
      nested_claude = File.join(home_claude, '.claude')

      stub(File).exist?(home_claude) { true }
      stub(Dir).exist?(/\.claude/) { |path|
        path == nested_claude ? false : nil
      }

      expect(described_class.find_nearest_pub(home_claude))
        .to eq({ name: 'global', path: global_dudes })
    end

    it 'strips trailing slashes from start path' do
      start_path = '/proj/src/feature/'
      proj_claude = '/proj/.claude'
      dudes_dir = File.join(proj_claude, 'dudes')

      stub(File).exist?('/proj/src/feature') { true }
      stub(Dir).exist?(/\.claude/) { |path|
        path == proj_claude
      }
      stub(described_class).find_pub_name_for_target(proj_claude) { 'myproj' }

      expect(described_class.find_nearest_pub(start_path))
        .to eq({ name: 'myproj', path: dudes_dir })
    end
  end

  describe '.find_pub_walking_up' do
    it 'returns pub when found in ancestry' do
      start_path = '/proj/src'
      proj_claude = '/proj/.claude'
      dudes_dir = File.join(proj_claude, 'dudes')

      stub(File).exist?(start_path) { true }
      stub(Dir).exist?(/\.claude/) { |path|
        path == proj_claude
      }
      stub(described_class).find_pub_name_for_target(proj_claude) { 'myproj' }

      expect(described_class.find_pub_walking_up(start_path))
        .to eq({ name: 'myproj', path: dudes_dir })
    end

    it 'returns nil when pub not found' do
      start_path = '/proj/src'

      stub(File).exist?(start_path) { true }
      stub(Dir).exist?(/\.claude/) { false }
      stub(described_class).find_pub_name_for_target { nil }

      expect(described_class.find_pub_walking_up(start_path))
        .to be_nil
    end

    it 'returns nil for nonexistent path' do
      start_path = '/nonexistent'

      stub(File).exist?(start_path) { false }

      expect(described_class.find_pub_walking_up(start_path))
        .to be_nil
    end
  end

  describe '.find_pub_name_for_target' do
    let(:global_dir) { File.expand_path('~/.claude/dudes') }

    it 'returns pub name when symlink matches' do
      target = '/proj/.claude'

      stub(Dir).exist?(global_dir) { true }
      stub(Dir).children(global_dir) { ['myproj'] }
      stub(File).symlink?(/myproj/) { true }
      stub(File).readlink(/myproj/) { '/proj/.claude/' }

      expect(described_class.find_pub_name_for_target(target))
        .to eq('myproj')
    end

    it 'returns nil when no symlink matches' do
      target = '/proj/.claude'

      stub(Dir).exist?(global_dir) { true }
      stub(Dir).children(global_dir) { ['other'] }
      stub(File).symlink?(/other/) { true }
      stub(File).readlink(/other/) { '/other/path/' }

      expect(described_class.find_pub_name_for_target(target))
        .to be_nil
    end

    it 'returns nil when global dir missing' do
      target = '/proj/.claude'

      stub(Dir).exist?(global_dir) { false }

      expect(described_class.find_pub_name_for_target(target))
        .to be_nil
    end

    it 'normalizes trailing slashes in comparison' do
      target = '/proj/.claude'

      stub(Dir).exist?(global_dir) { true }
      stub(Dir).children(global_dir) { ['myproj'] }
      stub(File).symlink?(/myproj/) { true }
      stub(File).readlink(/myproj/) { '/proj/.claude/' }

      expect(described_class.find_pub_name_for_target(target))
        .to eq('myproj')
    end
  end
end
