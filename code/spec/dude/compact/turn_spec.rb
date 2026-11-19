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

  def part(words)
    { 'type' => 'text', 'text' => words }
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

    it 'is false for a bare hook' do
      say '<hook>blorp</hook>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a system reminder' do
      say '<system-reminder>zarnok is blue</system-reminder>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a task notification' do
      say '<task-notification>sub done</task-notification>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a heartbeat' do
      say 'heartbeat: check the zarnok queue'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a scheduled task' do
      say '<scheduled-task>nightly sweep</scheduled-task>'

      expect(sut.ask?).to be(false)
    end

    it 'is false for an expanded skill body' do
      say 'Base directory for this skill: /frumble/skills/blorp'

      expect(sut.ask?).to be(false)
    end

    it 'is false for a meta skill body' do
      entry['isMeta'] = true
      say 'Base directory for this skill: /frumble/skills/blorp'

      expect(sut.ask?).to be(false)
    end

    it 'is true for a slash command' do
      say "<command-name>/zim</command-name>\n" \
          "<command-args>blorp now</command-args>"

      expect(sut.ask?).to be(true)
    end

    it 'is false for an interrupt' do
      say '[Request interrupted by user]'

      expect(sut.ask?).to be(false)
    end

    it 'is false for an image only turn' do
      say '[Image #2]'

      expect(sut.ask?).to be(false)
    end

    it 'is true for list content of human text parts' do
      say [
        part('ship'),
        part('it')
      ]

      expect(sut.ask?).to be(true)
    end

    it 'is true for human text after a noise part' do
      say [
        part('<system-reminder>zarnok is blue</system-reminder>'),
        part('ship it')
      ]

      expect(sut.ask?).to be(true)
    end

    it 'is false for list content of noise parts only' do
      say [
        part('<system-reminder>zarnok is blue</system-reminder>'),
        part('<hook>blorp</hook>')
      ]

      expect(sut.ask?).to be(false)
    end

    it 'is true for human text beside a text part without text' do
      say [
        part('frumble the parser'),
        { 'type' => 'text' }
      ]

      expect(sut.ask?).to be(true)
    end
  end

  describe '#text' do
    it 'returns string content as is' do
      expect(sut.text).to eq('ship the parser on Monday')
    end

    it 'joins the text blocks of list content' do
      say [
        part('one'),
        { 'type' => 'image' },
        part('two')
      ]

      expect(sut.text).to eq("one\ntwo")
    end

    it 'drops noise parts from list content' do
      say [
        part('<system-reminder>zarnok is blue</system-reminder>'),
        part('ship it'),
        part('<hook>blorp</hook>')
      ]

      expect(sut.text).to eq('ship it')
    end

    it 'drops text parts without text' do
      say [
        part('ship it'),
        { 'type' => 'text' }
      ]

      expect(sut.text).to eq('ship it')
    end

    it 'strips image tags' do
      say 'look at this [Image #3]'

      expect(sut.text).to eq('look at this')
    end

    it 'returns nil when list content holds a tool result' do
      say [{ 'type' => 'tool_result' }]

      expect(sut.text).to be_nil
    end

    it 'replaces a paste with [paste]' do
      say '<pasted_content id="1">zarnok frumble blorp</pasted_content>'

      expect(sut.text).to eq('[paste]')
    end

    it 'keeps the human text around a paste' do
      say 'look at this <pasted_content id="1">' \
          'zarnok frumble blorp</pasted_content> ship it'

      expect(sut.text).to eq('look at this [paste] ship it')
    end

    it 'returns a slash command as its name and args' do
      say "<command-message>zim</command-message>\n" \
          "<command-name>/zim</command-name>\n" \
          "<command-args>blorp now</command-args>"

      expect(sut.text).to eq('/zim blorp now')
    end
  end

  describe '#time' do
    it 'parses the entry timestamp' do
      expect(sut.time).to eq(Time.utc(2026, 11, 18, 14, 3, 0))
    end
  end
end
