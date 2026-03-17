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

  def spend_out(pct)
    spend = Statusline::SPEND_CAP * pct / 100.0
    mock = { 'results' => [{ 'metrics' => { 'spend' => spend }, 'breakdown' => { 'models' => {} } }] }
    session = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 25 } }
    capture { Statusline.new(session.to_json, activity: mock).run }
  end

  # Spend color
  def test_spend_green  = assert(spend_out(20).include?("\e[32m💰"))
  def test_spend_yellow = assert(spend_out(50).include?("\e[38;5;226m💰"))
  def test_spend_red    = assert(spend_out(80).include?("\e[31m💰"))

  # Active model bg
  def test_opus_bg   = assert(out('opus').include?("\e[41m"))
  def test_sonnet_bg = assert(out('sonnet').include?("\e[42m"))
  def test_haiku_bg  = assert(out('haiku').include?("\e[42m"))
  def test_active_model_white_on_red = assert(out('opus').include?("\e[41m\e[97m"))
  def test_active_model_white_on_green = assert(out('sonnet').include?("\e[42m\e[97m"))

  # Yellow bg gets black text for readability
  def test_active_model_black_on_yellow
    # haiku is cheap (green bg here), need a yellow scenario
    mock = { 'results' => [{ 'metrics' => { 'spend' => 10.0 }, 'breakdown' => { 'models' => {
      'claude-haiku-4-5' => { 'metrics' => { 'successful_requests' => 40, 'spend' => 5.0 } },
      'claude-opus-4-6' => { 'metrics' => { 'successful_requests' => 30, 'spend' => 5.0 } },
      'claude-sonnet-4-6' => { 'metrics' => { 'successful_requests' => 30, 'spend' => 5.0 } }
    }}}]}
    session = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 25 } }
    o = capture { Statusline.new(session.to_json, activity: mock).run }
    # opus at 33% cost = yellow
    assert o.include?("\e[48;5;226m\e[30m"), "yellow bg should get black text, got: #{o.inspect}"
  end

  # Model order by requests
  def test_model_order = assert(strip(out) =~ /🐸.*🎭.*🎸/)

  # Multiplier — all models always show superscript
  def test_multiplier = assert(strip(out).match?(/[²³⁴⁵⁶⁷⁸⁹]/))
  def model_out(models)
    mock = { 'results' => [{ 'metrics' => { 'spend' => 1.0 }, 'breakdown' => { 'models' => models } }] }
    session = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 25 } }
    strip(capture { Statusline.new(session.to_json, activity: mock).run })
  end

  def test_model_one_request
    s = model_out('claude-opus-4-6' => { 'metrics' => { 'successful_requests' => 1, 'spend' => 1.0 } })
    assert s.match?(/🎭 ?¹⁰/), "model with 1 request should show ¹⁰, got: #{s}"
  end

  def test_model_zero_requests
    s = model_out({})
    refute s.match?(/[🐸🎭🎸]/), "no requests should show no models"
  end

  def test_single_model_shows_10_others_0
    s = model_out('claude-opus-4-6' => { 'metrics' => { 'successful_requests' => 50, 'spend' => 5.0 } })
    assert s.match?(/🎭 ?¹⁰/), "only model should show ¹⁰, got: #{s}"
    assert s.match?(/🐸 ?⁰/), "unused model should show ⁰, got: #{s}"
    assert s.match?(/🎸 ?⁰/), "unused model should show ⁰, got: #{s}"
  end

  # Dudes
  DUDES_MOCK = [
    { name: 'dude', icon: '🎳', messages: 0, context: 25, current: true },
    { name: 'rec', icon: '🔴', messages: 3, context: 50, current: false },
    { name: 'smith', icon: '🤖', messages: 0, context: 80, current: false }
  ].freeze

  def dudes_out
    session = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 25 } }
    capture { Statusline.new(session.to_json, activity: MOCK, dudes: DUDES_MOCK).run }
  end

  def test_dudes_icons = assert(strip(dudes_out).include?('🎳') && strip(dudes_out).include?('🔴') && strip(dudes_out).include?('🤖'))
  def test_dudes_superscript = assert(strip(dudes_out).match?(/🔴 ?³/))
  def test_dudes_zero_superscript = assert(strip(dudes_out).match?(/🎳 ?⁰/))
  def test_dudes_section_after_models = assert(strip(dudes_out).index('🎭') < strip(dudes_out).index('🎳'))
  def test_current_dude_has_bg = assert(dudes_out.include?("\e[42m\e[97m🎳"))
  def test_non_current_dude_no_bg = refute(dudes_out.include?("\e[42m\e[97m🔴"))

  # Current dude at yellow context gets black text
  def test_current_dude_yellow_gets_black
    yellow_dudes = [{ name: 'dude', icon: '🎳', messages: 0, context: 50, current: true }]
    session = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 50 } }
    o = capture { Statusline.new(session.to_json, activity: MOCK, dudes: yellow_dudes).run }
    assert o.include?("\e[48;5;226m\e[30m🎳"), "yellow bg dude should get black text"
  end

  # Fake FS for pure unit tests
  class FakeFS
    def initialize(files: {}, dirs: [], symlinks: {})
      @files, @dirs, @symlinks = files, dirs, symlinks
      @written = {}
    end

    attr_reader :written

    def exist?(path) = @files.key?(path)
    def dir_exist?(path) = @dirs.include?(path)
    def read(path) = @files.fetch(path) { raise Errno::ENOENT, path }
    def write(path, data) = @written[path] = data
    def children(path) = @files.keys.concat(@symlinks.keys).filter_map { |k| k.delete_prefix("#{path}/").split('/').first if k.start_with?("#{path}/") }.uniq
    def symlink?(path) = @symlinks.key?(path)
    def readlink(path) = @symlinks.fetch(path)
  end

  def fake_all_dudes
    home = File.expand_path('~')
    FakeFS.new(
      files: {
        "#{home}/.claude/CLAUDE.md" => "---\nicon: 🎳\n---\n",
        "#{home}/.claude/dudes/inbox.json" => '[]',
        "#{home}/.claude/dudes/status.json" => '{"name": "dude", "context": 25}',
        '/proj/.claude/CLAUDE.md' => "---\nicon: 🔴\n---\n",
        '/proj/.claude/dudes/inbox.json' => '[{},{}]',
        '/proj/.claude/dudes/status.json' => '{"name": "rec", "context": 50}',
        '/smith/.claude/CLAUDE.md' => "---\nicon: 🤖\n---\n",
        '/smith/.claude/dudes/inbox.json' => '[{}]',
        '/smith/.claude/dudes/status.json' => '{"name": "smith", "context": 80}'
      },
      dirs: [
        "#{home}/.claude", "#{home}/.claude/dudes",
        '/proj/.claude', '/proj/.claude/dudes',
        '/smith/.claude', '/smith/.claude/dudes'
      ],
      symlinks: {
        "#{home}/.claude/dudes/dude" => "#{home}/.claude/",
        "#{home}/.claude/dudes/rec" => '/proj/.claude/',
        "#{home}/.claude/dudes/smith" => '/smith/.claude/'
      }
    )
  end

  # All dudes see all pub dudes
  def test_all_dudes_visible_from_sup
    fs = fake_all_dudes
    dudes = Statusline.new('{}', activity: MOCK, cwd: "#{File.expand_path('~')}/.claude", fs: fs).send(:load_dudes)
    assert_equal ['🎳', '🔴', '🤖'], dudes.map { |d| d[:icon] }
  end

  def test_all_dudes_visible_from_project
    fs = fake_all_dudes
    dudes = Statusline.new('{}', activity: MOCK, cwd: '/proj', fs: fs).send(:load_dudes)
    assert_equal ['🎳', '🔴', '🤖'], dudes.map { |d| d[:icon] }
  end

  def test_current_dude_marked_from_sup
    fs = fake_all_dudes
    dudes = Statusline.new('{}', activity: MOCK, cwd: "#{File.expand_path('~')}/.claude", fs: fs).send(:load_dudes)
    assert dudes.find { |d| d[:name] == 'dude' }[:current]
    refute dudes.find { |d| d[:name] == 'rec' }[:current]
  end

  def test_current_dude_marked_from_project
    fs = fake_all_dudes
    dudes = Statusline.new('{}', activity: MOCK, cwd: '/proj', fs: fs).send(:load_dudes)
    assert dudes.find { |d| d[:name] == 'rec' }[:current]
    refute dudes.find { |d| d[:name] == 'dude' }[:current]
  end

  def test_pub_dude_message_count
    fs = fake_all_dudes
    dudes = Statusline.new('{}', activity: MOCK, cwd: "#{File.expand_path('~')}/.claude", fs: fs).send(:load_dudes)
    assert_equal 2, dudes.find { |d| d[:name] == 'rec' }[:messages]
  end

  # Current dude uses live context_percentage, not status.json
  def test_current_dude_uses_live_context
    fs = fake_all_dudes
    session = { 'context_window' => { 'used_percentage' => 75 } }
    dudes = Statusline.new(session.to_json, activity: MOCK, cwd: "#{File.expand_path('~')}/.claude", fs: fs).send(:load_dudes)
    assert_equal 75, dudes.find { |d| d[:name] == 'dude' }[:context]
  end

  # Status.json — write context % as side effect
  def test_writes_status_json
    fs = fake_all_dudes
    session = { 'model' => { 'id' => 'claude-opus-4-6' }, 'context_window' => { 'used_percentage' => 42 } }
    home = File.expand_path('~')
    capture { Statusline.new(session.to_json, activity: MOCK, cwd: "#{home}/.claude", fs: fs).run }
    status = JSON.parse(fs.written["#{home}/.claude/dudes/status.json"])
    assert_equal 42, status['context']
  end

  def test_no_status_file_defaults_green
    fs = fake_all_dudes
    home = File.expand_path('~')
    fs.instance_variable_get(:@files).delete('/smith/.claude/dudes/status.json')
    out = capture { Statusline.new('{}', activity: MOCK, cwd: "#{home}/.claude", fs: fs).run }
    assert out.include?("\e[32m🤖"), "missing status.json should render green"
  end

  def test_pub_dude_colored_by_context
    fs = fake_all_dudes
    home = File.expand_path('~')
    out = capture { Statusline.new('{}', activity: MOCK, cwd: "#{home}/.claude", fs: fs).run }
    assert out.include?("\e[31m🤖"), "80% context should render red"
  end

  def test_current_dude_highlighted
    fs = fake_all_dudes
    home = File.expand_path('~')
    out = capture { Statusline.new('{}', activity: MOCK, cwd: "#{home}/.claude", fs: fs).run }
    assert out.include?("\e[42m\e[97m🎳"), "current dude should have bg highlight"
  end

  # Errors
  def test_invalid = refute_empty(capture { Statusline.new('bad', activity: MOCK).run })
  def test_empty   = refute_empty(capture { Statusline.new('{}', activity: MOCK).run })

  # Contract
  def test_api_contract
    raw = Statusline.new('{}').send(:activity_data)
    assert raw.dig('results', 0, 'metrics', 'spend') && raw.dig('results', 0, 'breakdown', 'models')
  end
end

