module Cuke
  module StatusLine
    class << self
      attr_accessor :world
    end

    POLLS = %w[Dudes]

    def self.verify(section_name, expected, color)
      if POLLS.include?(section_name)
        poll(section_name, expected, color)
      else
        snap(section_name, expected, color)
      end
    end

    def self.snap(section_name, expected, color)
      output = world.dude('status_line', stdin: world.status_json).strip
      check(Cuke::StatusLineResult.new(output)[section_name], expected, color)
    end

    def self.poll(section_name, expected, color)
      @last_error = nil
      do_wait_for(section_name, expected, color)
    rescue RuntimeError
      raise @last_error || $!
    end

    def self.do_wait_for(section_name, expected, color)
      world.wait_for("#{section_name} section") {
        wait_and_check(section_name, expected, color)
      }
    end

    def self.wait_and_check(section_name, expected, color)
      fetch_and_check(section_name, expected, color)
    rescue RuntimeError => e
      @last_error = e
      false
    end

    def self.fetch_and_check(section_name, expected, color)
      output = world.dude('status_line').strip
      check(Cuke::StatusLineResult.new(output)[section_name], expected, color)
      true
    end

    def self.check(section, expected, color)
      verify_content(section, expected)
      verify_color(section, color) if color
    end

    def self.verify_content(section, expected)
      parts = expected.split(' ')
      all_present = parts.all? { |part| section.cleaned.include?(part) }
      msg = "Expected '#{expected}' in section, got: #{section.cleaned}"
      raise msg unless all_present
    end

    def self.verify_color(section, color)
      color_sym = color.to_sym
      fg_code = ::Dude::StatusLine::Format::COLORS[color_sym]
      bg_code = ::Dude::StatusLine::Format::COLORS[:"bg_#{color}"]
      has_color = section.raw.include?(fg_code) || section.raw.include?(bg_code)
      raise "Expected color #{color} in output" unless has_color
    end

    def status_json
      json = { context_window: { used_percentage: @context_percent } }
      json[:model] = { id: @active_model } if @active_model
      json.to_json
    end

    def build_models_from_counts(counts)
      h, hc, s, sc, o, oc = counts
      {
        haiku: { count: h.to_i, cost: hc.to_i },
        sonnet: { count: s.to_i, cost: sc.to_i },
        opus: { count: o.to_i, cost: oc.to_i }
      }
    end

    def set_activity_response(models)
      breakdown, total_spend = build_models_breakdown(models)
      payload = activity_response_payload(total_spend, breakdown)
      Cuke::ActivityServer.set_response(payload)
    end

    def build_models_breakdown(models)
      models.reduce([{}, 0]) { |(bd, t), (m, d)|
        [bd.merge(model_metrics(m, d)), t + d[:count] * d[:cost]]
      }
    end

    def model_metrics(model, data)
      {
        model.to_s => {
          'metrics' => {
            'successful_requests' => data[:count],
            'spend' => data[:count] * data[:cost]
          }
        }
      }
    end

    def activity_response_payload(total_spend, breakdown)
      metrics = { 'spend' => total_spend }
      breakdown_data = { 'models' => breakdown }
      result = { 'metrics' => metrics, 'breakdown' => breakdown_data }
      { 'results' => [result] }
    end
  end
end
