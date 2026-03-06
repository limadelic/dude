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

  def initialize(json_input, activity: nil)
    @session = JSON.parse(json_input)
    @activity = activity
  rescue JSON::ParserError => e
    warn "Error parsing JSON: #{e.message}"
    @session = {}
  end

  def run
    puts build_status_line
  rescue StandardError => e
    warn "Error: #{e.message}"
    puts "🧠 [ERROR: #{e.class}]"
  end

  private

  def build_status_line
    [brain_section, spend_section, pomodoro_section, models_section].compact.join(' ')
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
  def spend_section
    spend_pct = fetch_spend_percentage
    bar(spend_pct, '💰', lo: 60, hi: 80)
  end

  def fetch_spend_percentage
    spend = activity_data.dig('results', 0, 'metrics', 'spend').to_f
    clamp((spend / SPEND_CAP * 100).round)
  rescue StandardError
    0
  end

  def activity_data = @activity || fetch_json(activity_url) || {}

  POMO_TYPES = {
    'long break' => [900, '🍏', :green],
    'break' => [300, '🍏', :green],
    'default' => [1500, '🍅', :red]
  }.freeze

  def pomodoro_section
    label, end_time = read_pomo_file
    return nil unless end_time&.> Time.now.to_i
    total, icon, color_key = pomo_config(label)
    bar(pomo_pct(total, end_time), icon, color: COLORS[color_key])
  rescue StandardError
    nil
  end

  def read_pomo_file
    return nil unless File.exist?(POMO_FILE)
    parts = File.read(POMO_FILE).split('|')
    return nil if parts[0] == 'transitioning'
    [parts[0], parts[1].to_i]
  end

  def pomo_config(label)
    POMO_TYPES[label] || POMO_TYPES[label&.match?(/break/) ? 'break' : 'default']
  end

  def pomo_pct(total, end_time) = ((total - (end_time - Time.now.to_i)) * 100 / total).round

  MODELS = [['haiku', '🐸'], ['opus', '🎭'], ['sonnet', '🎸']].freeze

  def models_section
    stats = fetch_model_stats
    return "" if stats.empty? || model_counts(stats).sum.zero?
    build_model_groups(stats).sort_by { |g| -g[0] }.map { |g| emoji_group(*g[1..]) }.join(' ')
  end

  def model_counts(stats) = MODELS.map { |m, _| sum_metric(stats, m, 'successful_requests').to_i }
  def model_costs(stats) = MODELS.map { |m, _| sum_metric(stats, m, 'spend') }

  def build_model_groups(stats)
    counts, costs = model_counts(stats), model_costs(stats)
    req_pcts = normalize_to_100(*counts.map { |c| percentage(c, counts.sum) })
    cost_pcts = costs.map { |c| costs.sum.zero? ? 0 : (c * 100 / costs.sum).round }
    current = @session.dig('model', 'id') || ''
    MODELS.each_with_index.map { |(m, emoji), i| [counts[i], emoji, req_pcts[i] / 10, current.include?(m), color_for_pct(cost_pcts[i])] }
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

  BG_MAP = { "\033[32m" => "\033[42m", "\033[38;5;226m" => "\033[48;5;226m", "\033[31m" => "\033[41m" }.freeze

  def emoji_group(emoji, count, active, color)
    mult = count == 1 ? '' : "x#{count}"
    active ? "#{BG_MAP[color]}#{color}#{emoji}#{COLORS[:reset]}#{color}#{mult}#{COLORS[:reset]}" : "#{color}#{emoji}#{mult}#{COLORS[:reset]}"
  end

  def bar(pct, emoji, lo: nil, hi: nil, color: nil)
    pct, color = clamp(pct), color || color_for_pct(pct, lo, hi)
    "#{color}#{emoji} #{'█' * (pct * 9 / 100.0).round}#{'░' * (9 - (pct * 9 / 100.0).round)}#{COLORS[:reset]}"
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
  Statusline.new(input).run
end
