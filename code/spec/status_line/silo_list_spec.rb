require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/silo_list'
require_relative '../../lib/dude/transcript/silo_usage'

describe Dude::StatusLine::SiloList do
  include_context 'band spec setup'

  let(:silo_usage) do
    mock_silo_usage(
      costs: { 'silo-1' => 10, 'silo-2' => 8, 'silo-3' => 5 },
      active_count: 3
    )
  end

  let(:registry) do
    mock_registry(
      'dude' => { 'id' => 'silo-1', 'emoji' => '🧙' },
      'other_silo' => { 'id' => 'silo-2', 'emoji' => '🎯' },
      'third' => { 'id' => 'silo-3', 'emoji' => '🔥' }
    )
  end

  let(:sut) { described_class.new(silo_usage, registry) }

  describe '#call' do
    context 'when all silos are green (ratio < 2)' do
      it 'returns empty string' do
        expect(sut.call).to eq('')
      end
    end

    context 'when one silo is yellow' do
      let(:silo_usage) do
        mock_silo_usage(
          costs: { 'silo-1' => 30, 'silo-2' => 10, 'silo-3' => 5 },
          active_count: 3
        )
      end

      it 'returns emoji with yellow band background' do
        result = sut.call
        expect(result).to include('🧙')
        expect(result).to include("\033[48;5;226m")
        expect(result).to include("\033[0m")
      end
    end

    context 'when one silo is red' do
      let(:silo_usage) do
        mock_silo_usage(
          costs: {
            'silo-1' => 90, 'silo-2' => 10, 'silo-3' => 10, 'silo-4' => 10
          },
          active_count: 4
        )
      end

      let(:registry) do
        mock_registry(
          'dude' => { 'id' => 'silo-1', 'emoji' => '🧙' },
          'other_silo' => { 'id' => 'silo-2', 'emoji' => '🎯' },
          'third' => { 'id' => 'silo-3', 'emoji' => '🔥' },
          'fourth' => { 'id' => 'silo-4', 'emoji' => '💧' }
        )
      end

      it 'returns emoji with red band background' do
        result = sut.call
        expect(result).to include('🧙')
        expect(result).to include("\033[41m")
        expect(result).to include("\033[0m")
      end
    end

    context 'when ordering hottest first' do
      let(:silo_usage) do
        mock_silo_usage(
          costs: {
            'silo-1' => 600, 'silo-2' => 500, 'silo-3' => 100, 'silo-4' => 100,
            'silo-5' => 100, 'silo-6' => 100
          },
          active_count: 6
        )
      end

      let(:registry) do
        mock_registry(
          'dude' => { 'id' => 'silo-1', 'emoji' => '🧙' },
          'other_silo' => { 'id' => 'silo-2', 'emoji' => '🎯' },
          'third' => { 'id' => 'silo-3', 'emoji' => '🔥' },
          'fourth' => { 'id' => 'silo-4', 'emoji' => '💧' },
          'fifth' => { 'id' => 'silo-5', 'emoji' => '⚡' },
          'sixth' => { 'id' => 'silo-6', 'emoji' => '🌪️' }
        )
      end

      it 'orders by cost descending' do
        result = sut.call
        expect(result).to match(/🧙.*🎯/)
      end
    end

    context 'when more than 6 hot silos' do
      let(:silo_usage) do
        costs = {}
        (1..7).each { |i| costs["silo-#{i}"] = 800 }
        (8..15).each { |i| costs["silo-#{i}"] = 50 }
        mock_silo_usage(costs: costs, active_count: 15)
      end

      let(:registry) do
        registry_data = {}
        (1..7).each do |i|
          registry_data["silo#{i}"] = build_silo_data(i, "#{i}️⃣")
        end
        (8..15).each do |i|
          registry_data["silo#{i}"] = build_silo_data(i, "#{i % 10}️⃣")
        end
        mock_registry(registry_data)
      end

      it 'shows 6 emojis and appends +N' do
        result = sut.call
        expect(result).to match(/\+1/)
        emoji_count = result.scan(/\d️⃣/).length
        expect(emoji_count).to eq(6)
      end
    end

    context 'when silo has no emoji' do
      let(:silo_usage) do
        mock_silo_usage(
          costs: {
            'silo-1' => 1000, 'silo-2' => 100, 'silo-3' => 900, 'silo-4' => 100,
            'silo-5' => 100, 'silo-6' => 100, 'silo-7' => 100, 'silo-8' => 100
          },
          active_count: 8
        )
      end

      let(:registry) do
        mock_registry(
          'dude' => { 'id' => 'silo-1', 'emoji' => '🧙' },
          'other_silo' => { 'id' => 'silo-2', 'emoji' => nil },
          'third' => { 'id' => 'silo-3', 'emoji' => '🔥' },
          'fourth' => { 'id' => 'silo-4', 'emoji' => '💧' },
          'fifth' => { 'id' => 'silo-5', 'emoji' => '⚡' },
          'sixth' => { 'id' => 'silo-6', 'emoji' => '🌪️' },
          'seventh' => { 'id' => 'silo-7', 'emoji' => '🌊' },
          'eighth' => { 'id' => 'silo-8', 'emoji' => '🌪️' }
        )
      end

      it 'skips silo with nil emoji' do
        result = sut.call
        expect(result).not_to include('silo-2')
        expect(result).to include('🧙')
        expect(result).to include('🔥')
      end
    end

    context 'when other silo is present' do
      let(:silo_usage) do
        mock_silo_usage(
          costs: { 'silo-1' => 30, 'silo-2' => 10, 'other' => 100 },
          active_count: 3
        )
      end

      let(:registry) do
        mock_registry(
          'dude' => { 'id' => 'silo-1', 'emoji' => '🧙' },
          'other_silo' => { 'id' => 'silo-2', 'emoji' => '🎯' },
          'other' => { 'id' => 'other', 'emoji' => '❓' }
        )
      end

      it 'excludes other from list' do
        result = sut.call
        expect(result).not_to include('❓')
      end
    end
  end

  private

  def mock_silo_usage(costs:, active_count:)
    double('SiloUsage').tap { |u| stub_silo_usage(u, costs, active_count) }
  end

  def stub_silo_usage(usage, costs, active_count)
    stub_sessions(usage, costs.keys.to_h { |k| [k, k] })
    allow(usage).to receive(:cost) { |id| costs[id] || 0 }
    allow(usage).to receive(:active_count).and_return(active_count)
    stub_ratio(usage, costs, active_count)
  end

  def stub_sessions(usage, sessions_to_silos)
    allow(usage).to receive(:instance_variable_get)
      .with(:@sessions_to_silos).and_return(sessions_to_silos)
  end

  def stub_ratio(usage, costs, active_count)
    allow(usage).to receive(:ratio) do |id|
      calculate_ratio(id, costs, active_count)
    end
  end

  def calculate_ratio(silo_id, costs, active_count)
    cost = costs[silo_id] || 0
    return nil if cost == 0

    average = costs.values.sum / active_count.to_f
    cost / average
  end

  def build_silo_data(i, emoji)
    { 'id' => "silo-#{i}", 'emoji' => emoji }
  end

  def mock_registry(silos_data)
    registry = double('registry')
    allow(registry).to receive(:instance_variable_get)
      .with(:@roster)
      .and_return(silos_data)
    allow(registry).to receive(:emoji) { |n| silos_data[n]&.dig('emoji') }
    allow(registry).to receive(:silo_id) { |n| silos_data[n]&.dig('id') }
    registry
  end
end
