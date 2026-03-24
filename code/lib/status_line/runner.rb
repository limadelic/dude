require 'json'
require 'open3'
require 'date'
require_relative '../helpers/fs'
require_relative '../helpers/json'
require_relative 'format'
require_relative '../pomo/pomo'
require_relative '../dudes/dudes'
require_relative 'context'
require_relative 'spend'
require_relative 'models'

module StatusLine; end

class StatusLine::Runner
  include StatusLine::Format

  COLORS = StatusLine::Format::COLORS
  SUPERSCRIPTS = StatusLine::Format::SUPERSCRIPTS
  BG_MAP = StatusLine::Format::BG_MAP
  WHITE = StatusLine::Format::WHITE
  JETBRAINS = StatusLine::Format::JETBRAINS

  def initialize(json_input, activity: nil, dudes: nil, cwd: Dir.pwd, fs: nil)
    fs ||= Helpers::FS.new
    @session = (JSON.parse(json_input) rescue (warn "Error parsing JSON: #{$!.message}"; {}))
    @activity, @dudes, @cwd, @fs = activity, dudes, cwd, fs
  end

  def run
    puts build_status_line(create_dudes_instance.tap(&:write_status))
  rescue StandardError => e
    handle_error(e)
  end

  private

  def create_dudes_instance
    Dudes::Renderer.new(@session, @dudes, @cwd, @fs, context_percentage)
  end

  def handle_error(e)
    warn "Error: #{e.message}"
    puts "🧠 [ERROR: #{e.class}]"
  end

  def build_status_line(dudes_instance)
    [context_section, spend_section, pomo_section, models_section, dudes_instance.render].compact.join(' ')
  end

  def context_section
    StatusLine::Context.new(@session, context_percentage).render
  end

  def context_percentage
    pct = @session.dig('context_window', 'used_percentage') || 0
    clamp(pct)
  end

  def load_dudes
    dudes_instance = Dudes::Renderer.new(@session, @dudes, @cwd, @fs, context_percentage)
    dudes_instance.send(:load_dudes)
  end

  def spend_section
    StatusLine::Spend.new(activity_data).render
  end

  def activity_data = @activity || fetch_json(activity_url) || {}

  def pomo_section
    Pomo::Timer.new(@fs).render
  end

  def models_section
    StatusLine::Models.new(@session, activity_data).render
  end


  def activity_url
    today = Date.today.strftime('%Y-%m-%d')
    "https://sdlc-llm.ukg.int/user/daily/activity?start_date=#{today}&end_date=#{today}"
  end

  def fetch_json(url)
    out, _, status = run_curl(url)
    status.success? && JSON.parse(out) rescue nil
  end

  def run_curl(url)
    Open3.capture3('curl', '-s', '-L', url, '-H', "x-litellm-api-key: #{ENV['ANTHROPIC_AUTH_TOKEN']}", '--cacert', File.expand_path('~/.claude/ukg.pem'))
  end
end
