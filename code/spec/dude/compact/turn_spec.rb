require_relative '../../spec_helper'
require_relative '../../../lib/dude/compact/turn'

describe Dude::Compact::Turn do
  let(:sut) { described_class.new(entry) }
  let(:entry) {
    {
      'type' => 'user', 'timestamp' => stamp,
      'message' => { 'content' => 'ship the parser on Monday' }
    }
  }
  let(:stamp) { '2026-11-18T14:03:00Z' }

  def say(words)
    entry['message']['content'] = words
  end

  describe '#ask?' do
    it 'is true for a human text turn' do
      expect(sut.ask?).to be(true)
    end

    it 'is false for an assistant turn' do
      entry['type'] = 'assistant'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a meta turn' do
      entry['isMeta'] = true

      expect(sut.ask?).to be(false)
    end

    it 'is false for a compact summary' do
      entry['isCompactSummary'] = true

      expect(sut.ask?).to be(false)
    end

    it 'is false for a tool result' do
      say [{ 'type' => 'tool_result' }]

      expect(sut.ask?).to be(false)
    end

    it 'is false for a peer message' do
      say '<cross-session-message>ship it</cross-session-message>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a hook' do
      say '<user-prompt-submit-hook>go</user-prompt-submit-hook>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a system reminder' do
      say '<system-reminder>riley is blue</system-reminder>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a task notification' do
      say '<task-notification>sub done</task-notification>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for an interrupt' do
      say '[Request interrupted by user]'

      expect(sut.ask?).to be(false)
    end

    it 'is false for an image only turn' do
      say '[Image #2]'

      expect(sut.ask?).to be(false)
    end
  end

  describe '#text' do
    it 'returns string content as is' do
      expect(sut.text).to eq('ship the parser on Monday')
    end

    it 'joins the text blocks of list content' do
      say [
        { 'type' => 'text', 'text' => 'one' },
        { 'type' => 'image' },
        { 'type' => 'text', 'text' => 'two' }
      ]

      expect(sut.text).to eq("one\ntwo")
    end

    it 'strips image tags' do
      say 'look at this [Image #3]'

      expect(sut.text).to eq('look at this')
    end

    it 'returns nil when list content holds a tool result' do
      say [{ 'type' => 'tool_result' }]

      expect(sut.text).to be_nil
    end
  end

  describe '#time' do
    it 'parses the entry timestamp' do
      expect(sut.time).to eq(Time.parse(stamp))
    end
  end
end
