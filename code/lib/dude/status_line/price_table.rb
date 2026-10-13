require 'json'
require_relative '../model_families'

module Dude
  module StatusLine
    class PriceTable
      def initialize
        @rates = load_rates
      end

      def cost(model, usage)
        family = extract_model_family(model)
        rates = @rates[family] || handle_unknown_model(model)
        calculate_cost(rates, usage)
      end

      private

      def load_rates
        path = File.join(__dir__, 'price_rates.json')
        JSON.parse(File.read(path))
      end

      def extract_model_family(model)
        Dude::ModelFamilies::ALL
          .find { |family_name, _emoji| model.include?(family_name) }
          &.[](0)
      end

      def handle_unknown_model(model)
        warn "Unknown model: #{model}"
        @rates['opus']
      end

      def calculate_cost(rates, usage)
        input = cost_for_tokens(usage, 'input_tokens', rates['input'])
        output = cost_for_tokens(usage, 'output_tokens', rates['output'])
        cache_create = cache_creation_cost(usage, rates)
        cache_read = cache_read_cost(usage, rates)
        input + output + cache_create + cache_read
      end

      def cost_for_tokens(usage, token_key, rate)
        (usage.fetch(token_key, 0) / 1_000_000.0) * rate
      end

      def cache_creation_cost(usage, rates)
        token_key = 'cache_creation_input_tokens'
        cost_for_tokens(usage, token_key, rates['cache_creation'])
      end

      def cache_read_cost(usage, rates)
        cost_for_tokens(usage, 'cache_read_input_tokens', rates['cache_read'])
      end
    end
  end
end
