require 'webrick'
require 'socket'
require 'json'

module Cuke
  def self.find_free_port
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    port
  end

  class ActivityServer
    @@server = nil
    @@response_data = {}

    def self.start
      return if @@server

      port = Cuke.find_free_port
      @@server = create_server(port)
      setup_server_route
      start_server_thread(port)
    end

    def self.create_server(port)
      WEBrick::HTTPServer.new(
        Port: port,
        AccessLog: [],
        Logger: WEBrick::Log.new('/dev/null')
      )
    end

    def self.setup_server_route
      @@server.mount_proc '/' do |req, res|
        res['Content-Type'] = 'application/json'
        res.body = @@response_data.to_json
      end
    end

    def self.start_server_thread(port)
      Thread.new { @@server.start }
      sleep 0.1
      ENV['CLAUDE_ACTIVITY_URL'] = "http://127.0.0.1:#{port}/"
    end

    def self.stop
      if @@server
        @@server.shutdown
        @@server = nil
      end
    end

    def self.set_response(data)
      @@response_data = data
    end
  end
end
