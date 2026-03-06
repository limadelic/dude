#!/usr/bin/env ruby
require 'minitest/autorun'
require_relative '../statusline'

class StatuslineTest < Minitest::Test
  MOCK = { 'results' => [{ 'metrics' => { 'spend' => 10.0 }, 'breakdown' => { 'models' => {
    'claude-haiku-4-5' => { 'metrics' => { 'successful_requests' => 50, 'spend' => 0.5 } },
    'claude-opus-4-6' => { 'metrics' => { 'successful_requests' => 30, 'spend' => 15.0 } },
    'claude-sonnet-4-6' => { 'metrics' => { 'successful_requests' => 20, 'spend' => 4.0 } }
  }}}]}.freeze

  def out(model = 'opus', pct = 25)
    session = { 'model' => { 'id' => "claude-#{model}-4-6" }, 'context_window' => { 'used_percentage' => pct } }
    capture { Statusline.new(session.to_json, activity: MOCK).run }
  end

  def capture = (o = StringIO.new; $stdout = o; yield; $stdout = STDOUT; o.string)
  def strip(s) = s.gsub(/\e\[[0-9;]*m/, '')

  # Structure
  def test_has_sections = assert(strip(out).match?(/🧠.*💰.*[🎭🎸🐸]/))

  # Order
  def test_order = assert(strip(out).index("🧠") < strip(out).index("💰"))

  # Bar = 9 blocks
  def test_bar_length = assert_equal(9, strip(out)[/🧠 ([█░]+)/, 1]&.length)

  # Context fill
  { 0 => 0, 33 => 3, 66 => 6, 100 => 9 }.each do |pct, blocks|
    define_method("test_ctx_#{pct}") { assert_equal(blocks, strip(out('opus', pct))[/🧠 ([█░]+)/, 1]&.count("█")) }
  end

  # Context color
  def test_ctx_green  = assert(out('opus', 25).include?("\e[32m🧠"))
  def test_ctx_yellow = assert(out('opus', 50).include?("\e[38;5;226m🧠"))
  def test_ctx_red    = assert(out('opus', 80).include?("\e[31m🧠"))

  # Active model bg
  def test_opus_bg   = assert(out('opus').include?("\e[41m"))
  def test_sonnet_bg = assert(out('sonnet').include?("\e[42m"))
  def test_haiku_bg  = assert(out('haiku').include?("\e[42m"))

  # Model order by requests
  def test_model_order = assert(strip(out) =~ /🐸.*🎭.*🎸/)

  # Multiplier
  def test_multiplier = assert(strip(out).match?(/x\d+/))

  # Errors
  def test_invalid = refute_empty(capture { Statusline.new('bad', activity: MOCK).run })
  def test_empty   = refute_empty(capture { Statusline.new('{}', activity: MOCK).run })

  # Contract
  def test_api_contract
    raw = Statusline.new('{}').send(:activity_data)
    assert raw.dig('results', 0, 'metrics', 'spend') && raw.dig('results', 0, 'breakdown', 'models')
  end
end

