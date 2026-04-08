module Examples
  module Shared
    require_relative '../../lib/dude/status_line/runner'

    RSpec.shared_examples 'color threshold' do |low, mid, high|
      it 'is green at low threshold' do
        expect(output_at_percentage(low)).to include("\e[32m")
      end

      it 'is yellow at mid threshold' do
        expect(output_at_percentage(mid)).to include("\e[38;5;226m")
      end

      it 'is red at high threshold' do
        expect(output_at_percentage(high)).to include("\e[31m")
      end
    end

    RSpec.shared_context 'StatusLine helpers' do
      let(:session) { mock_session('opus', 25).to_json }
      let(:activity) { mock_activity }

      def mock_session(model = 'opus', context = 25)
        {
          'model' => { 'id' => "claude-#{model}-4-6" },
          'context_window' => { 'used_percentage' => context }
        }
      end

      def default_models
        {
          'claude-haiku-4-5' => {
            'metrics' => {
              'successful_requests' => 50,
              'spend' => 0.5
            }
          },
          'claude-opus-4-6' => {
            'metrics' => {
              'successful_requests' => 30,
              'spend' => 15.0
            }
          },
          'claude-sonnet-4-6' => {
            'metrics' => {
              'successful_requests' => 20,
              'spend' => 4.0
            }
          }
        }
      end

      def mock_activity(spend: 10.0, models: nil)
        m = models || default_models
        {
          'results' => [
            {
              'metrics' => { 'spend' => spend },
              'breakdown' => { 'models' => m }
            }
          ]
        }
      end

      def out(session_data, activity_data = activity, dudes_data = nil)
        json_session = if session_data.nil?
                         mock_session.to_json
                       elsif session_data.is_a?(String)
                         session_data
                       else
                         session_data.to_json
                       end
        capture_output do
          Dude::StatusLine::Runner.new(
            json_session, activity: activity_data,
            dudes: dudes_data
          ).run
        end
      end
    end
  end
end
