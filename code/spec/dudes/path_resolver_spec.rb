require 'spec_helper'

module Dude
  module Dudes
    describe PathResolver do
      let(:sut) { described_class.new }

      describe '#expand_target' do
        context 'absolute path' do
          it 'returns as-is without trailing slash' do
            expect(
              sut.expand_target(
                '/absolute/path/',
                '/any/dir'
              )
            ).to eq('/absolute/path')
          end

          it 'returns unchanged when no trailing slash' do
            expect(
              sut.expand_target(
                '/absolute/path',
                '/any/dir'
              )
            ).to eq('/absolute/path')
          end
        end

        context 'relative path' do
          it 'resolves against dudes_dir' do
            expect(
              sut.expand_target(
                'relative/path',
                '/home/user'
              )
            ).to eq('/home/user/relative/path')
          end
        end

        context 'path with parent reference' do
          it 'pops parent directory' do
            expect(
              sut.expand_target(
                '../other',
                '/home/user/dudes'
              )
            ).to eq('/home/user/other')
          end

          it 'handles multiple parent references' do
            expect(
              sut.expand_target(
                '../../root',
                '/home/user/dudes'
              )
            ).to eq('/home/root')
          end
        end

        context 'path with current directory reference' do
          it 'skips single dot component' do
            expect(
              sut.expand_target(
                './path',
                '/home/user'
              )
            ).to eq('/home/user/path')
          end

          it 'skips dot in middle of path' do
            expect(
              sut.expand_target(
                'nested/./path',
                '/home/user'
              )
            ).to eq('/home/user/nested/path')
          end
        end

        context 'complex paths' do
          it 'combines parent and current references' do
            expect(
              sut.expand_target(
                '../foo/./bar',
                '/a/b/c'
              )
            ).to eq('/a/b/foo/bar')
          end

          it 'strips trailing slash from readlink result' do
            expect(
              sut.expand_target(
                'rel/path/',
                '/root'
              )
            ).to eq('/root/rel/path')
          end
        end
      end
    end
  end
end
