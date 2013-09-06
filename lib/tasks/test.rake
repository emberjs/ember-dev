namespace :ember do
  desc "Run tests with phantomjs"
  task :test, [:suite] => :dist do |t, args|
    require "rack"
    require "webrick"
    require "colored"

    unless sh("which phantomjs > /dev/null 2>&1")
      abort "PhantomJS is not installed. Download from http://phantomjs.org"
    end

    packages = Dir['packages/*/tests'].sort.map { |p| p.split('/')[1] }

    suites = {
      'default'  => packages.map{|p| "package=#{p}" },
    }

    packages.each do |package|
      suites[package] = ["package=#{package}"]
    end

    if EmberDev.config.testing_suites
      suites.merge!(EmberDev.config.testing_suites)
    end

    # This is a bit of a hack
    suites.each do |name, opts|
      if idx = opts.index('EACH_PACKAGE')
        opts[idx] = packages.map{|package| "package=#{package}" }
        opts.flatten!
      end
    end

    if ENV['TEST']
      opts = [ENV['TEST']]
    else
      suite = args[:suite] || 'default'
      opts = suites[suite]
    end

    unless opts
      abort "No suite named: #{suite}"
    end

    port = ENV['TEST_SERVER_PORT'] || 60099
    server = Thread.new do
      Rack::Server.start(:config => "config.ru",
                         :Logger => WEBrick::Log.new("/dev/null"),
                         :AccessLog => [],
                         :Port => port)
    end

    begin
      success = true
      opts.each do |opt|
        puts "\n"

        test_path = File.expand_path("../../../support/tests", __FILE__)
        cmd = "phantomjs #{test_path}/qunit/run-qunit.js \"http://localhost:#{port}/?#{opt}\""

        # If the command fails, don't thrown an exception
        sh(cmd) rescue nil

        # The command might have failed due to a timeout. If so, try again.
        tries = 0
        while tries < 3 && $?.exitstatus === 124
          tries += 1
          puts "\nTimed Out. Trying again...\n"
          sh(cmd) rescue nil
        end

        success &&= $?.success?
      end
    ensure
      server.kill
    end

    if success
      puts "\nTests Passed".green
    else
      puts "\nTests Failed".red
      exit(1)
    end
  end

  desc "Automatically run tests (Mac OS X only)"
  task :autotest do
    sh("kicker -e 'rake test' packages")
  end
end
