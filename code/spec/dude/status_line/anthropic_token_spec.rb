require_relative '../../spec_helper'
require 'dude/status_line/anthropic_token'
require 'open3'

describe Dude::StatusLine::AnthropicToken do
  include RR::DSL
  let(:sut) { described_class }

  describe '.fetch' do
    it 'returns token from credentials.json when present' do
      creds_path = File.expand_path('~/.claude/.credentials.json')
      creds = { 'claudeAiOauth' => { 'accessToken' => 'test_token_123' } }
      stub(File).exist?(creds_path) { true }
      stub(File).read(creds_path) { JSON.generate(creds) }

      token = sut.fetch

      expect(token).to eq('test_token_123')
    end

    it 'returns empty string when credentials.json missing' do
      creds_path = File.expand_path('~/.claude/.credentials.json')
      stub(File).exist?(creds_path) { false }
      failed = Object.new
      def failed.success?; false; end
      stub(Open3).capture3(
        anything, anything, anything, anything, anything,
        anything
      ) {
        ['', '', failed]
      }

      token = sut.fetch

      expect(token).to eq('')
    end

    it 'returns empty string when JSON parse fails' do
      creds_path = File.expand_path('~/.claude/.credentials.json')
      stub(File).exist?(creds_path) { true }
      stub(File).read(creds_path) { 'invalid json {{{' }
      failed = Object.new
      def failed.success?; false; end
      stub(Open3).capture3(
        anything, anything, anything, anything, anything,
        anything
      ) {
        ['', '', failed]
      }

      token = sut.fetch

      expect(token).to eq('')
    end

    it 'returns empty string when accessToken missing' do
      creds_path = File.expand_path('~/.claude/.credentials.json')
      creds = { 'claudeAiOauth' => { 'someOtherField' => 'value' } }
      stub(File).exist?(creds_path) { true }
      stub(File).read(creds_path) { JSON.generate(creds) }
      failed = Object.new
      def failed.success?; false; end
      stub(Open3).capture3(
        anything, anything, anything, anything, anything,
        anything
      ) {
        ['', '', failed]
      }

      token = sut.fetch

      expect(token).to eq('')
    end
  end
end
