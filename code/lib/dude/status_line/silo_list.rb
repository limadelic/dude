require_relative '../transcript/band'
require_relative 'format'

module Dude
  module StatusLine
    class SiloList
      include Dude::StatusLine::Format
      COLORS = Dude::StatusLine::Format::COLORS

      def initialize(silo_usage, registry)
        @silo_usage = silo_usage
        @registry = registry
      end

      def call
        hot_silos = find_hot_silos
        return '' if hot_silos.empty?

        emojis = build_emoji_list(hot_silos)
        emojis.join
      end

      private

      def find_hot_silos
        all_silos = @silo_usage
          .instance_variable_get(:@sessions_to_silos)
          .values.uniq

        hot_silos = all_silos.select { |id| hot?(id) }
        hot_silos.sort_by { |silo_id| @silo_usage.cost(silo_id) }.reverse
      end

      def hot?(silo_id)
        return false if silo_id.nil? || silo_id == 'other'

        cost = @silo_usage.cost(silo_id)
        return false if cost == 0

        ratio = @silo_usage.ratio(silo_id)
        ratio && ratio >= 2.0
      end

      def build_emoji_list(hot_silos)
        silo_names = find_silo_names(hot_silos)
        emojis = collect_emojis(silo_names)
        emojis.length <= 6 ? emojis : cap_emojis(emojis)
      end

      def collect_emojis(silo_names)
        silo_names.each_with_object([]) { |name, list| add_emoji(name, list) }
      end

      def add_emoji(name, list)
        emoji = @registry.emoji(name) || return
        band_color = band_for(@registry.silo_id(name))
        list << format_emoji(emoji, band_color) if band_color
      end

      def cap_emojis(emojis)
        displayed = emojis.slice(0, 6)
        displayed << "+#{emojis.length - 6}"
      end

      def band_for(silo_id)
        ratio = @silo_usage.ratio(silo_id)
        Dude::Transcript::Band.new(ratio, @silo_usage.active_count).color
      end

      def find_silo_names(hot_silo_ids)
        all_silos = @registry.instance_variable_get(:@roster)
        all_silos.select do |_, data|
          hot_silo_ids.include?(data&.dig('id'))
        end.keys
      end

      def format_emoji(emoji, band)
        bg = band == :yellow ? COLORS[:bg_yellow] : COLORS[:bg_red]
        "#{bg}#{emoji}#{COLORS[:reset]}"
      end
    end
  end
end
