require "rack"
require "webrick"
require "colored"

module EmberDev
  class TestRunner

    def self.with_server
      start_server
      wait_for_server
      yield
    ensure
      stop_server
    end

    def self.run(params)
      new(params).run
    end

    def self.server_port
      ENV['TEST_SERVER_PORT'] || 60099
    end

    def server_port
      self.class.server_port
    end

    def self.start_server
      @server_pid ||= fork do
        Rack::Server.start(:config => "config.ru",
                           :Logger => WEBrick::Log.new("/dev/null"),
                           :AccessLog => [],
                           :Port => server_port.to_i)
      end
    end

    def self.stop_server
      return true unless @server_pid

      Process.kill 'INT', @server_pid
      @server_pid = nil
    end

    def self.server_ready?
      sock = Socket.new(:INET, :STREAM)
      raw = Socket.sockaddr_in(server_port, "0.0.0.0")
      sock.connect(raw)
      true
    rescue (Errno::ECONNREFUSED)
    rescue(Errno::ETIMEDOUT)
    end

    def self.wait_for_server(timeout = 1)
      start_server unless @server_pid

      start_time = Time.now
      loop do
        break if server_ready?
        if Time.now - start_time > timeout
          raise 'Could not connect to server.'
        end

        sleep 0.1
      end
    end

    attr_reader :test_params

    def initialize(test_options, options = {})
      @test_params          = test_options
      @phantom_path         = options.fetch(:phantom_path) { nil }
      @javascript_test_path = options.fetch(:javascript_test_path) { nil }
    end

    def javascript_test_path
      @javascript_test_path ||= File.expand_path("../../../support/tests", __FILE__)
    end

    def test_command
      "#{phantom_path} #{javascript_test_path}/qunit/run-qunit.js \"http://localhost:#{server_port}/?#{test_params}\""
    end

    def phantom_path
      @phantom_path ||= 'phantomjs'
    end

    def run
      system(test_command)

      # A bit of a hack until we can figure this out on Travis
      tries = 0
      while tries < 3 && $?.exitstatus === 124
        tries += 1
        puts "\nTimed Out. Trying again...\n"
        system(test_command)
      end

      $?.success?
    end
  end
end
