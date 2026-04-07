require 'tempfile'
require 'time'

module Cuke
  module Pomo
    def create_pomo_file(label, end_time)
      file = Tempfile.new('pomo_status')
      file.write("#{label}|#{end_time}")
      file.close
      file
    end

    def setup_pomo(label, total_secs, mins_passed)
      elapsed = mins_passed * 60
      end_time = Time.now.to_i + (total_secs - elapsed)
      @pomo_file = create_pomo_file(label, end_time)
      ENV['POMO_STATUS_FILE'] = @pomo_file.path
    end
  end
end
