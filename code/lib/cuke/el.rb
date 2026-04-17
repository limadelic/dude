# frozen_string_literal: true

require "open3"
require "json"

module Cuke
  module El
    def spawn_claude
      cmd = build_claude_cmd
      @claude_stdin, @claude_stdout, @claude_stderr, @claude_thread =
        Open3.popen3(cmd)
      sleep 0.1 # give process time to start
    end

    def build_claude_cmd
      "claude -p --input-format=stream-json " \
      "--output-format=stream-json --verbose"
    end

    def send_message(msg)
      message_obj = {
        type: "user",
        message: { role: "user", content: msg },
        parent_tool_use_id: nil
      }
      @claude_stdin.puts message_obj.to_json
      @claude_stdin.flush
    end

    def read_response(timeout = 30)
      find_result_within(timeout)
    end

    def cleanup_claude
      return unless @claude_thread

      close_streams
      kill_process
    end

    private

    def find_result_within(timeout)
      deadline = Time.now + timeout
      loop_for_result(deadline)
    end

    def loop_for_result(deadline)
      while Time.now < deadline
        result = try_parse_result(read_line)
        return handle_result(result) if result
      end
      raise "Timeout waiting for response"
    end

    def read_line
      line = @claude_stdout.gets
      raise "Process died" if line.nil?

      line
    end

    def try_parse_result(line)
      data = JSON.parse(line)
      data if data["type"] == "result"
    rescue JSON::ParserError
      nil
    end

    def handle_result(data)
      raise "Response failed: #{data.inspect}" unless success?(data)

      data["result"]
    end

    def success?(data)
      data["subtype"] == "success"
    end

    def close_streams
      @claude_stdin.close rescue nil
      @claude_stdout.close rescue nil
      @claude_stderr.close rescue nil
    end

    def kill_process
      Process.kill("TERM", -@claude_thread.pid) rescue nil
      @claude_thread.join(5) rescue nil
    end
  end
end
