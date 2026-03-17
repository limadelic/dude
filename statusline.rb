#!/usr/bin/env ruby
require 'json'
require 'open3'
require 'date'

class Statusline
  # ANSI color codes
  COLORS = {
    red: "\033[31m",
    green: "\033[32m",
    yellow: "\033[38;5;226m",
    reset: "\033[0m",
    bg_green: "\033[42m",
    bg_red: "\033[41m",
    bg_yellow: "\033[48;5;226m"
  }.freeze

  SPEND_CAP = ENV.fetch('CLAUDE_SPEND_CAP', '50').to_i
  POMO_FILE = '/tmp/pomo.status'
  SUPERSCRIPTS = { 0 => '⁰', 1 => '¹', 2 => '²', 3 => '³', 4 => '⁴', 5 => '⁵', 6 => '⁶', 7 => '⁷', 8 => '⁸', 9 => '⁹', 10 => '¹⁰' }.freeze
  BG_MAP = { "\033[32m" => "\033[42m", "\033[38;5;226m" => "\033[48;5;226m", "\033[31m" => "\033[41m" }.freeze
  WHITE = "\033[97m".freeze
  BLACK = "\033[30m".freeze
  JETBRAINS = ENV['TERMINAL_EMULATOR'] == 'JetBrains-JediTerm'
  MODELS = [['haiku', '🐸'], ['opus', '🎭'], ['sonnet', '🎸']].freeze
  POMO_TYPES = {
    'long break' => [900, '🍏', :green],
    'break' => [300, '🍏', :green],
    'default' => [1500, '🍅', :red]
  }.freeze

  module FS
    module_function
    def exist?(path) = File.exist?(path)
    def dir_exist?(path) = Dir.exist?(path)
    def read(path) = File.read(path)
    def write(path, data) = File.write(path, data)
    def children(path) = Dir.children(path)
    def symlink?(path) = File.symlink?(path)
    def readlink(path) = File.readlink(path)
  end

  def initialize(json_input, activity: nil, dudes: nil, cwd: Dir.pwd, fs: FS)
    @session = (JSON.parse(json_input) rescue (warn "Error parsing JSON: #{$!.message}"; {}))
    @activity, @dudes, @cwd, @fs = activity, dudes, cwd, fs
  end

  def run
    write_status
    puts build_status_line
  rescue StandardError => e
    warn "Error: #{e.message}"
    puts "🧠 [ERROR: #{e.class}]"
  end

  private

  def claude_dir
    @claude_dir ||= (c = File.expand_path('.claude', @cwd); @fs.dir_exist?(c) ? c : @cwd)
  end

  def dudes_dir = File.join(claude_dir, 'dudes')
  def dude_dir = File.join(claude_dir, 'dudes')
  def claude_md = File.join(claude_dir, 'CLAUDE.md')

  def build_status_line
    [brain_section, spend_section, pomodoro_section, models_section, dudes_section].compact.join(' ')
  end

  # Brain (context window usage)
  def brain_section
    bar(context_percentage, '🧠', lo: 33, hi: 66)
  end

  def context_percentage
    pct = @session.dig('context_window', 'used_percentage') || 0
    clamp(pct)
  end

  # Money (spend cap usage)
  def spend_pct
    spend = activity_data.dig('results', 0, 'metrics', 'spend').to_f rescue 0
    [clamp((spend / SPEND_CAP * 100).round), spend > 0 ? 1 : 0]
  end

  def spend_section
    pct, min = spend_pct
    blocks = [pct * 9 / 100, min].max
    "#{color_for_pct(pct)}💰 #{'█' * blocks}#{'░' * (9 - blocks)}#{COLORS[:reset]}"
  end

  def activity_data = @activity || fetch_json(activity_url) || {}

  def pomodoro_section
    label, end_time = read_pomo_file
    return nil unless end_time&.> Time.now.to_i
    total, icon, color_key = pomo_config(label)
    bar(pomo_pct(total, end_time), icon, color: COLORS[color_key]) rescue nil
  end

  def read_pomo_file
    return nil unless @fs.exist?(POMO_FILE)
    parts = @fs.read(POMO_FILE).split('|')
    return nil if parts[0] == 'transitioning'
    [parts[0], parts[1].to_i]
  end

  def pomo_config(label)
    POMO_TYPES[label] || POMO_TYPES[label&.match?(/break/) ? 'break' : 'default']
  end

  def pomo_pct(total, end_time) = ((total - (end_time - Time.now.to_i)) * 100 / total).round

  def models_section
    stats = fetch_model_stats
    return "" if stats.empty? || model_counts(stats).sum.zero?
    build_model_groups(stats).sort_by { |g| -g[0] }.map { |g| emoji_group(*g[1..]) }.join(' ')
  end

  def model_counts(stats) = MODELS.map { |m, _| sum_metric(stats, m, 'successful_requests').to_i }
  def model_costs(stats) = MODELS.map { |m, _| sum_metric(stats, m, 'spend') }

  def cost_pcts(costs)
    costs.map { |c| costs.sum.zero? ? 0 : (c * 100 / costs.sum).round }
  end

  def build_model_groups(stats)
    counts, costs = model_counts(stats), model_costs(stats)
    pcts = normalize_to_100(*counts.map { |c| percentage(c, counts.sum) })
    cpcts = cost_pcts(costs)
    current = @session.dig('model', 'id') || ''
    MODELS.each_with_index.map { |(m, e), i| [counts[i], e, pcts[i] / 10, current.include?(m), color_for_pct(cpcts[i])] }
  end

  def fetch_model_stats
    activity_data.dig('results', 0, 'breakdown', 'models') || {}
  rescue StandardError
    {}
  end

  def sum_metric(groups, model_name, key)
    groups.select { |k, _| k.include?(model_name) }
          .sum { |_, v| v.dig('metrics', key).to_f }
  end

  # Dudes
  def write_status
    return unless @fs.dir_exist?(dude_dir)
    path = File.join(dude_dir, 'status.json')
    existing = (JSON.parse(@fs.read(path)) rescue {})
    @fs.write(path, existing.merge('context' => context_percentage).to_json) rescue nil
  end

  def dudes_section
    dudes = @dudes || load_dudes
    dudes.empty? ? nil : dudes.map { |d| dude_display(d) }.join(' ') rescue nil
  end

  def dude_display(d)
    emoji_group(d[:icon], d[:messages], d[:current], color_for_pct(d[:context] || 0))
  end

  def load_dudes
    global_dudes_dir = File.expand_path('~/.claude/dudes')
    return [] unless @fs.dir_exist?(global_dudes_dir)
    @fs.children(global_dudes_dir).sort.filter_map { |name| load_pub_dude(name, global_dudes_dir) }
  end

  def load_pub_dude(name, dir)
    path = File.join(dir, name)
    return nil unless @fs.symlink?(path)
    target = @fs.readlink(path)
    current = target.chomp('/') == claude_dir.chomp('/')
    dude = File.join(target, 'dudes')
    icon = read_icon(File.join(target, 'CLAUDE.md'))
    ctx = current ? context_percentage : read_context(dude)
    icon ? { name: name, icon: icon, messages: read_inbox(dude), context: ctx, current: current } : nil
  end

  def read_context(dir)
    JSON.parse(@fs.read(File.join(dir, 'status.json')))['context'] rescue 0
  end

  def read_icon(path)
    return nil unless @fs.exist?(path)
    @fs.read(path)[/^---\s*\n(.*?\n)---\s*\n/m, 1]&.[](/^icon:\s*(.+)/, 1)&.strip
  end

  def read_inbox(dir)
    JSON.parse(@fs.read(File.join(dir, 'inbox.json'))).length rescue 0
  end

  def emoji_str(emoji, color, sup, pad)
    "#{color}#{emoji}#{pad}#{sup}#{COLORS[:reset]}"
  end

  def emoji_group(emoji, count, active, color)
    sup, pad = SUPERSCRIPTS[count] || '⁹⁺', JETBRAINS ? ' ' : ''
    fg = color == COLORS[:yellow] ? BLACK : WHITE
    active ? "#{BG_MAP[color]}#{fg}#{emoji}#{pad}#{sup}#{COLORS[:reset]}" : emoji_str(emoji, color, sup, pad)
  end

  def bar(pct, emoji, lo: 33, hi: 66, color: nil)
    pct = clamp(pct)
    filled = (pct * 9 / 100.0).round
    "#{color || color_for_pct(pct, lo, hi)}#{emoji} #{'█' * filled}#{'░' * (9 - filled)}#{COLORS[:reset]}"
  end

  def color_for_pct(pct, lo = 33, hi = 66)
    case pct
    when 0...lo then COLORS[:green]
    when lo...hi then COLORS[:yellow]
    else COLORS[:red]
    end
  end

  def percentage(part, total)
    total.zero? ? 0 : (part * 100 / total).round
  end

  def round_to_10(n)
    ((n + 5) / 10) * 10
  end

  def normalize_to_100(a, b, c)
    rounded = [a, b, c].map { |n| round_to_10(n) }
    rounded[[a, b, c].index([a, b, c].max)] += 100 - rounded.sum
    rounded
  end

  def clamp(value)
    [[value.to_i, 0].max, 100].min
  end

  def activity_url
    today = Date.today.strftime('%Y-%m-%d')
    "https://sdlc-llm.ukg.int/user/daily/activity?start_date=#{today}&end_date=#{today}"
  end

  def fetch_json(url)
    out, _, status = Open3.capture3('curl', '-s', '-L', url, '-H', "x-litellm-api-key: #{ENV['ANTHROPIC_AUTH_TOKEN']}", '--cacert', File.expand_path('~/.claude/ukg.pem'))
    status.success? ? JSON.parse(out) : nil
  rescue StandardError
    nil
  end
end

if $0 == __FILE__
  input = STDIN.read
  input = '{}' if input.strip.empty?
  Statusline.new(input).run
end
