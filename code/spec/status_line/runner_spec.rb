require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/runner'

describe Dude::StatusLine::Runner do
  include RR::DSL

  describe 'context bar rendering' do
    let(:sut) { described_class.new(input.to_json) }

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      stub(ENV).[] do |key|
        key == 'CLAUDE_CODE_AUTO_COMPACT_WINDOW' ? nil : ENV.fetch(key, nil)
      end
    end

    context 'with token counts' do
      let(:input) do
        {
          'context_window' => {
            'total_input_tokens' => 124000,
            'total_output_tokens' => 0,
            'context_window_size' => 1000000,
            'used_percentage' => 12
          }
        }
      end

      it 'renders 7 filled blocks from tokens (74%)' do
        output = capture_output { sut.run }
        bar_match = strip(output)[/🧠 ([█░]+)/, 1]

        expect(bar_match.count('█')).to eq(7)
      end
    end

    context 'with fallback used_percentage' do
      let(:input) do
        {
          'context_window' => {
            'used_percentage' => 9
          }
        }
      end

      it 'renders 1 filled block from used_percentage (9%, min-fill)' do
        output = capture_output { sut.run }
        bar_match = strip(output)[/🧠 ([█░]+)/, 1]

        expect(bar_match.count('█')).to eq(1)
      end
    end

    context 'with no context_window' do
      let(:input) { {} }

      it 'renders 0 filled blocks (0%)' do
        output = capture_output { sut.run }
        bar_match = strip(output)[/🧠 ([█░]+)/, 1]

        expect(bar_match.count('█')).to eq(0)
      end
    end

    context 'with zero context_window_size' do
      let(:input) do
        {
          'context_window' => {
            'total_input_tokens' => 0,
            'total_output_tokens' => 0,
            'context_window_size' => 0,
            'used_percentage' => 9
          }
        }
      end

      it 'renders 1 filled block from fallback (9%, min-fill)' do
        output = capture_output { sut.run }
        bar_match = strip(output)[/🧠 ([█░]+)/, 1]

        expect(bar_match.count('█')).to eq(1)
      end
    end
  end

  describe 'rate limit rendering' do
    let(:sut) { described_class.new(input.to_json) }

    context 'with rate_limits key (Pro/Max)' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' },
          'rate_limits' => {
            'five_hour' => {
              'used_percentage' => 41,
              'resets_at' => (Time.now.to_i + 3600)
            },
            'seven_day' => {
              'used_percentage' => 4,
              'resets_at' => (Time.now.to_i + 86400 * 3)
            }
          }
        }
      end

      it 'renders both sun and moon emojis' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
        expect(output).to include('🌙')
      end
    end

    context 'without rate_limits key (Enterprise)' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' }
        }
      end

      before do
        stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      end

      it 'renders neither sun nor moon emojis' do
        output = capture_output { sut.run }

        expect(output).not_to include('☀️')
        expect(output).not_to include('🌙')
      end

      it 'still renders context bar' do
        output = capture_output { sut.run }

        expect(output).to include('█')
        expect(output).to include('🧠')
        expect(output).to include('🎭')
      end
    end

    context 'with only five_hour rate limit' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' },
          'rate_limits' => {
            'five_hour' => {
              'used_percentage' => 41,
              'resets_at' => (Time.now.to_i + 3600)
            }
          }
        }
      end

      it 'renders sun emoji but not moon' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
        expect(output).not_to include('🌙')
      end
    end

    context 'with only seven_day rate limit' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' },
          'rate_limits' => {
            'seven_day' => {
              'used_percentage' => 4,
              'resets_at' => (Time.now.to_i + 86400 * 3)
            }
          }
        }
      end

      it 'renders moon emoji but not sun' do
        output = capture_output { sut.run }

        expect(output).not_to include('☀️')
        expect(output).to include('🌙')
      end
    end
  end

  describe 'band rendering' do
    let(:sut) { described_class.new(input.to_json, dudes: nil, cwd: cwd) }
    let(:cache) { instance_double(Dude::Transcript::UsageCache) }
    let(:cache_store) { instance_double(Dude::Transcript::UsageCacheStore) }
    let(:registry) { instance_double(Dude::Transcript::SiloRegistry) }
    let(:current_silo) { instance_double(Dude::Transcript::CurrentSilo) }
    let(:silo_usage) { instance_double(Dude::Transcript::SiloUsage) }
    let(:band) { instance_double(Dude::Transcript::Band) }
    let(:cwd) { Dir.pwd }
    let(:input) do
      {
        'context_window' => { 'used_percentage' => 10 },
        'model' => { 'id' => 'claude-opus-4-8' },
        'rate_limits' => {
          'five_hour' => {
            'used_percentage' => 41,
            'resets_at' => (Time.now.to_i + 3600)
          }
        }
      }
    end

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      stub(Dude::Transcript::UsageCacheStore).new { cache_store }
      stub(cache_store).load { cache }
      stub(Dude::Transcript::SiloRegistry).new { registry }
      stub(registry).load
      stub(registry).roster { {} }
      stub(Dude::Transcript::CurrentSilo).new { current_silo }
      stub(Dude::Transcript::SiloUsage).new { silo_usage }
      stub(Dude::Transcript::Band).new { band }
    end

    context 'when cache loads successfully and band is computed' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).ratio { 2.5 }
        stub(silo_usage).active_count { 2 }
        stub(band).color { :yellow }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '☀️ bar')
        end
      end

      it 'passes band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('☀️ bar')
      end
    end

    context 'when silo is nil' do
      before do
        stub(current_silo).call { nil }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '☀️ bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
      end
    end

    context 'when cache is empty' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).active_count { 0 }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '☀️ bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
      end
    end

    context 'when active_count is 1 (solo)' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).active_count { 1 }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '☀️ bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
      end
    end

    context 'when band color is nil (green)' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).ratio { 1.5 }
        stub(silo_usage).active_count { 2 }
        stub(band).color { nil }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '☀️ bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
      end
    end

    context 'when input lacks rate_limits' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' }
        }
      end

      it 'does not compute band' do
        output = capture_output { sut.run }

        expect(output).not_to include('☀️')
      end
    end

    context 'when input lacks five_hour rate_limit' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' },
          'rate_limits' => {
            'seven_day' => {
              'used_percentage' => 4,
              'resets_at' => (Time.now.to_i + 86400 * 3)
            }
          }
        }
      end

      it 'does not compute band' do
        output = capture_output { sut.run }

        expect(output).not_to include('☀️')
      end
    end
  end

  describe 'no band rendering' do
    let(:sut) { described_class.new(input.to_json, dudes: nil, cwd: Dir.pwd) }
    let(:input) do
      {
        'context_window' => { 'used_percentage' => 41 },
        'model' => { 'id' => 'claude-opus-4-8' },
        'rate_limits' => {
          'five_hour' => {
            'used_percentage' => 41,
            'resets_at' => (Time.now.to_i + 3600)
          },
          'seven_day' => {
            'used_percentage' => 4,
            'resets_at' => (Time.now.to_i + 86400 * 3)
          }
        }
      }
    end

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      stub(Dude::Pomo::Pomo).new { instance_double(Dude::Pomo::Pomo, to_s: nil) }
      stub(Dude::Transcript::UsageCacheStore).new { cache_store }
      stub(cache_store).load { cache }
      stub(Dude::Transcript::SiloRegistry).new { registry }
      stub(registry).load
      stub(registry).roster { {} }
      stub(Dude::Transcript::CurrentSilo).new { current_silo }
      stub(Dude::Transcript::SiloUsage).new { silo_usage }
      stub(current_silo).call { nil }
    end

    let(:cache_store) { instance_double(Dude::Transcript::UsageCacheStore) }
    let(:cache) { instance_double(Dude::Transcript::UsageCache) }
    let(:registry) { instance_double(Dude::Transcript::SiloRegistry) }
    let(:current_silo) { instance_double(Dude::Transcript::CurrentSilo) }
    let(:silo_usage) { instance_double(Dude::Transcript::SiloUsage) }

    it 'renders rate limits without background band on sun emoji' do
      output = capture_output { sut.run }
      expected_output = (
        "\e[38;5;226m🧠 ████░░░░░\e[0m \e[32m☀️ ████░░░░░\e[0m " \
        "\e[32m🌙 █░░░░░░░░\e[0m 🎭 \n"
      )

      expect(output).to eq(expected_output)
    end
  end

  describe 'silo_list rendering' do
    let(:sut) { described_class.new(input.to_json, dudes: nil, cwd: Dir.pwd) }
    let(:registry) { instance_double(Dude::Transcript::SiloRegistry) }
    let(:silo_usage) { instance_double(Dude::Transcript::SiloUsage) }
    let(:silo_list) { instance_double(Dude::StatusLine::SiloList) }
    let(:five_hour_band) { instance_double(Dude::StatusLine::SunBand) }
    let(:input) do
      {
        'context_window' => { 'used_percentage' => 10 },
        'model' => { 'id' => 'claude-opus-4-8' },
        'rate_limits' => {
          'five_hour' => {
            'used_percentage' => 41,
            'resets_at' => (Time.now.to_i + 3600)
          }
        }
      }
    end

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      stub(Dude::StatusLine::SunBand).new { five_hour_band }
      stub(five_hour_band).call { nil }
      stub(five_hour_band).silo_list_data { [silo_usage, registry] }
      stub(Dude::StatusLine::SiloList).new { silo_list }
    end

    context 'when a silo is hot' do
      before do
        stub(silo_list).call { '🧙' }
      end

      it 'shows silo_list after five_hour section' do
        output = capture_output { sut.run }

        expect(output).to match(/☀️.*🧙/)
      end
    end

    context 'when silo_list is empty' do
      before do
        stub(silo_list).call { '' }
      end

      it 'adds no section' do
        output = capture_output { sut.run }

        expect(output).to include('☀️')
        expect(output).not_to include('🧙')
      end
    end

    context 'when five_hour rate_limit is absent' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' },
          'rate_limits' => {
            'seven_day' => {
              'used_percentage' => 4,
              'resets_at' => (Time.now.to_i + 86400 * 3)
            }
          }
        }
      end

      it 'adds no section' do
        output = capture_output { sut.run }

        expect(output).not_to include('🧙')
      end
    end
  end

  describe 'red band rendering' do
    let(:sut) { described_class.new(input.to_json, dudes: nil, cwd: Dir.pwd) }
    let(:band) { instance_double(Dude::Transcript::Band) }
    let(:cache) { instance_double(Dude::Transcript::UsageCache) }
    let(:cache_store) { instance_double(Dude::Transcript::UsageCacheStore) }
    let(:cache_checker) { instance_double(Dude::Transcript::CacheStalenessChecker) }
    let(:registry) { instance_double(Dude::Transcript::SiloRegistry) }
    let(:current_silo) { instance_double(Dude::Transcript::CurrentSilo) }
    let(:silo_usage) { instance_double(Dude::Transcript::SiloUsage) }
    let(:input) do
      {
        'context_window' => { 'used_percentage' => 41 },
        'model' => { 'id' => 'claude-opus-4-8' },
        'rate_limits' => {
          'five_hour' => {
            'used_percentage' => 99,
            'resets_at' => (Time.now.to_i + 3600)
          },
          'seven_day' => {
            'used_percentage' => 4,
            'resets_at' => (Time.now.to_i + 86400 * 3)
          }
        }
      }
    end

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      stub(Dude::Transcript::UsageCacheStore).new { cache_store }
      stub(cache_store).load { cache }
      stub(cache).instance_variable_get { {} }
      stub(Dude::Transcript::SiloRegistry).new { registry }
      stub(registry).load
      stub(registry).roster { {} }
      stub(Dude::Transcript::CurrentSilo).new { current_silo }
      stub(Dude::Transcript::SiloUsage).new { silo_usage }
      stub(Dude::Transcript::Band).new { band }
      stub(Dude::Transcript::CacheStalenessChecker).new { cache_checker }
      stub(cache_checker).stale? { false }
      stub(current_silo).call { 'uuid-code' }
      stub(silo_usage).active_count { 2 }
      stub(silo_usage).ratio('uuid-code') { 3.5 }
      stub(band).color { :red }
    end

    it 'renders red background code before sun emoji' do
      output = capture_output { sut.run }

      expect(output).to include("\e[41m☀️")
    end

    it 'renders red background code before moon emoji' do
      output = capture_output { sut.run }

      expect(output).to include("\e[41m🌙")
    end
  end

  describe 'moon band rendering' do
    let(:sut) { described_class.new(input.to_json, dudes: nil, cwd: cwd) }
    let(:cache) { instance_double(Dude::Transcript::UsageCache) }
    let(:cache_store) { instance_double(Dude::Transcript::UsageCacheStore) }
    let(:registry) { instance_double(Dude::Transcript::SiloRegistry) }
    let(:current_silo) { instance_double(Dude::Transcript::CurrentSilo) }
    let(:silo_usage) { instance_double(Dude::Transcript::SiloUsage) }
    let(:band) { instance_double(Dude::Transcript::Band) }
    let(:cwd) { Dir.pwd }
    let(:input) do
      {
        'context_window' => { 'used_percentage' => 10 },
        'model' => { 'id' => 'claude-opus-4-8' },
        'rate_limits' => {
          'seven_day' => {
            'used_percentage' => 41,
            'resets_at' => (Time.now.to_i + 86400 * 3)
          }
        }
      }
    end

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
      stub(Dude::Transcript::UsageCacheStore).new { cache_store }
      stub(cache_store).load { cache }
      stub(Dude::Transcript::SiloRegistry).new { registry }
      stub(registry).load
      stub(registry).roster { {} }
      stub(Dude::Transcript::CurrentSilo).new { current_silo }
      stub(Dude::Transcript::SiloUsage).new { silo_usage }
      stub(Dude::Transcript::Band).new { band }
    end

    context 'when cache loads successfully and band is computed' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).ratio { 2.5 }
        stub(silo_usage).active_count { 2 }
        stub(band).color { :yellow }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '🌙 bar')
        end
      end

      it 'passes band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('🌙 bar')
      end
    end

    context 'when silo is nil' do
      before do
        stub(current_silo).call { nil }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '🌙 bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('🌙')
      end
    end

    context 'when cache is empty' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).active_count { 0 }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '🌙 bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('🌙')
      end
    end

    context 'when band color is nil (green)' do
      before do
        stub(current_silo).call { 'uuid-code' }
        stub(silo_usage).ratio { 1.5 }
        stub(silo_usage).active_count { 2 }
        stub(band).color { nil }
        stub(Dude::StatusLine::RateLimit).new do
          double(to_s: '🌙 bar')
        end
      end

      it 'passes no band to rate_limit' do
        output = capture_output { sut.run }

        expect(output).to include('🌙')
      end
    end

    context 'when input lacks seven_day rate_limit' do
      let(:input) do
        {
          'context_window' => { 'used_percentage' => 10 },
          'model' => { 'id' => 'claude-opus-4-8' },
          'rate_limits' => {
            'five_hour' => {
              'used_percentage' => 41,
              'resets_at' => (Time.now.to_i + 3600)
            }
          }
        }
      end

      it 'does not compute band' do
        output = capture_output { sut.run }

        expect(output).not_to include('🌙')
      end
    end
  end
end
