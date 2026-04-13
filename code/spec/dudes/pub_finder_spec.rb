require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/pub_finder"

describe Dude::Dudes::PubFinder do
  include RR::DSL

  describe '.find_nearest_pub' do
    let(:proj_claude) { '/proj/.claude' }
    let(:dudes_dir) { File.join(proj_claude, 'dudes') }
    let(:global_dudes) { File.expand_path('~/.claude/dudes') }

    before do
      stub(File).exist?(anything) { true }
      stub(Dir).exist?(anything) { false }
      stub(described_class).find_pub_name_for_target(anything) { nil }
    end

    it 'finds pub in parent directory' do
      stub(Dir).exist?(proj_claude) { true }
      stub(described_class).find_pub_name_for_target(proj_claude) { 'myproj' }

      expect(described_class.find_nearest_pub('/proj/src/feature'))
        .to eq({ name: 'myproj', path: dudes_dir })
    end

    it 'walks up multiple directory levels' do
      abc_claude = '/a/b/c/.claude'
      stub(Dir).exist?(abc_claude) { true }
      stub(described_class).find_pub_name_for_target(abc_claude) { 'abc' }

      expect(described_class.find_nearest_pub('/a/b/c/d/e/f'))
        .to eq({ name: 'abc', path: File.join(abc_claude, 'dudes') })
    end

    it 'returns global pub when walking up finds nothing' do
      expect(described_class.find_nearest_pub('/proj/src/file.rb'))
        .to eq({ name: 'global', path: global_dudes })
    end

    it 'chooses nearest pub over distant' do
      b_claude = '/a/b/.claude'
      stub(Dir).exist?(b_claude) { true }
      stub(described_class).find_pub_name_for_target(b_claude) { 'b' }

      expect(described_class.find_nearest_pub('/a/b/c'))
        .to eq({ name: 'b', path: File.join(b_claude, 'dudes') })
    end

    it 'returns global pub when start path does not exist' do
      stub(File).exist?('/nonexistent/path') { false }

      expect(described_class.find_nearest_pub('/nonexistent/path'))
        .to eq({ name: 'global', path: global_dudes })
    end

    it 'returns global pub for ~/.claude itself' do
      home_claude = File.expand_path('~/.claude')
      nested_claude = File.join(home_claude, '.claude')
      stub(Dir).exist?(nested_claude) { false }

      expect(described_class.find_nearest_pub(home_claude))
        .to eq({ name: 'global', path: global_dudes })
    end

    it 'strips trailing slashes from start path' do
      stub(Dir).exist?(proj_claude) { true }
      stub(described_class).find_pub_name_for_target(proj_claude) { 'myproj' }

      expect(described_class.find_nearest_pub('/proj/src/feature/'))
        .to eq({ name: 'myproj', path: dudes_dir })
    end
  end

  describe '.find_pub_walking_up' do
    let(:proj_claude) { '/proj/.claude' }
    let(:dudes_dir) { File.join(proj_claude, 'dudes') }

    before do
      stub(File).exist?(anything) { true }
      stub(Dir).exist?(anything) { false }
      stub(described_class).find_pub_name_for_target(anything) { nil }
    end

    it 'returns pub when found in ancestry' do
      stub(Dir).exist?(proj_claude) { true }
      stub(described_class).find_pub_name_for_target(proj_claude) { 'myproj' }

      expect(described_class.find_pub_walking_up('/proj/src'))
        .to eq({ name: 'myproj', path: dudes_dir })
    end

    it 'returns nil when pub not found' do
      expect(described_class.find_pub_walking_up('/proj/src'))
        .to be_nil
    end

    it 'returns nil for nonexistent path' do
      stub(File).exist?('/nonexistent') { false }

      expect(described_class.find_pub_walking_up('/nonexistent'))
        .to be_nil
    end
  end

  describe '.find_pub_name_for_target' do
    let(:registry) { instance_double('SymlinkRegistry') }
    let(:target) { '/proj/.claude' }

    before do
      stub(described_class).registry { registry }
      stub(registry).find_name_for_target(anything) { nil }
    end

    it 'returns pub name when symlink matches' do
      stub(registry).find_name_for_target(target) { 'myproj' }

      expect(described_class.find_pub_name_for_target(target))
        .to eq('myproj')
    end

    it 'returns nil when no symlink matches' do
      expect(described_class.find_pub_name_for_target(target))
        .to be_nil
    end
  end
end
