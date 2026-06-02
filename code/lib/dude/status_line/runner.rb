require 'json'
require_relative '../helpers/json'
require_relative 'format'
require_relative '../pomo/pomo'
require_relative '../dudes/dudes'
require_relative 'context'
require_relative 'spend'
require_relative 'models'
require_relative 'dudes'
require_relative 'anthropic_token'
require_relative 'anthropic_spend_client'
require_relative 'spend_cache'

module Dude
  module StatusLine
    class Runner
      include Dude::StatusLine::Format

      COLORS = Dude::StatusLine::Format::COLORS
      SUPERSCRIPTS = Dude::StatusLine::Format::SUPERSCRIPTS
      BG_MAP = Dude::StatusLine::Format::BG_MAP
      WHITE = Dude::StatusLine::Format::WHITE
      JETBRAINS = Dude::StatusLine::Format::JETBRAINS

      def initialize(json_input, activity: nil, dudes: nil, cwd: Dir.pwd)
        @session = (JSON.parse(json_input) rescue default_session)
        @activity, @dudes, @cwd = activity, dudes, cwd
      end

      def run
        puts build_status_line(create_dudes_instance.tap(&:write_status))
      rescue StandardError => e
        handle_error(e)
      end

      private

      def default_session
        warn "Error parsing JSON: #{$!.message}"
        {}
      end

      def create_dudes_instance
        Dude::StatusLine::Dudes.new(
          @session, dudes_list, @cwd, context_percentage
        )
      end

      def dudes_list
        @dudes_list ||= @dudes || load_dudes
      end

      def handle_error(e)
        warn "Error: #{e.message}"
        puts "🧠 [ERROR: #{e.class}]"
      end

      def build_status_line(dudes_instance)
        sections = [
          context_section, spend_section, pomo_section,
          models_section, dudes_instance.to_s
        ]
        sections.compact.join(' ')
      end

      def context_section
        Dude::StatusLine::Context.new(@session, context_percentage).to_s
      end

      def context_percentage
        @context_percentage ||= begin
          pct = @session.dig('context_window', 'used_percentage') || 0
          clamp(pct)
        end
      end

      def load_dudes
        Dude::Dudes::Dudes.new.all
      end

      def spend_section
        token_fetcher = Dude::StatusLine::AnthropicToken
        client = Dude::StatusLine::AnthropicSpendClient.new(token_fetcher.fetch)
        Dude::StatusLine::Spend.new(token_fetcher, client).to_s
      end

      def activity_data
        @activity_data ||= @activity || {}
      end

      def pomo_section
        Dude::Pomo::Pomo.new.to_s
      end

      def models_section
        Dude::StatusLine::Models.new(@session, activity_data).to_s
      end
    end
  end
end
