namespace :ember do
  desc "Run tests with phantomjs"
  task :test, [:suite] => :dist do |t, args|
    require "rack"
    require "webrick"
    require "colored"

    unless system("which phantomjs > /dev/null 2>&1")
      abort "PhantomJS is not installed. Download from http://phantomjs.org"
    end

    packages = Dir['packages/*/tests'].sort.map { |p| p.split('/')[1] }

    suites = {
      :default  => packages.map{|p| "package=#{p}" },
      :built    => [ "package=all&dist=build" ],
      :runtime  => [ "package=ember-metal,ember-runtime" ],
      :views    => [ "package=container,ember-views,ember-handlebars" ],
      :standard => packages.map{|p| "package=#{p}" } +
                    ["package=all&jquery=1.7.2&nojshint=true",
                      "package=all&extendprototypes=true&nojshint=true",
                      # container isn't publicly available in the built version
                      "package=all&skipPackage=container&dist=build&nojshint=true"],
      :all      => packages.map{|p| "package=#{p}" } +
                    ["package=all&jquery=1.7.2&nojshint=true",
                      "package=all&jquery=1.8.3&nojshint=true",
                      "package=all&jquery=git&nojshint=true",
                      "package=all&extendprototypes=true&nojshint=true",
                      "package=all&extendprototypes=true&jquery=git&nojshint=true",
                      # container isn't publicly available in the built version
                      "package=all&skipPackage=container&dist=build&nojshint=true"]
    }

    packages.each do |package|
      suites[package.to_sym] = ["package=#{package}"]
    end

    if ENV['TEST']
      opts = [ENV['TEST']]
    else
      suite = args[:suite] || :default
      opts = suites[suite.to_sym]
    end

    unless opts
      abort "No suite named: #{suite}"
    end

    server = fork do
      Rack::Server.start(:config => "config.ru",
                         :Logger => WEBrick::Log.new("/dev/null"),
                         :AccessLog => [],
                         :Port => 9999)
    end

    success = true
    opts.each do |opt|
      puts "\n"

      test_path = File.expand_path("../../../support/tests", __FILE__)
      cmd = "phantomjs #{test_path}/qunit/run-qunit.js \"http://localhost:9999/?#{opt}\""
      system(cmd)

      # A bit of a hack until we can figure this out on Travis
      tries = 0
      while tries < 3 && $?.exitstatus === 124
        tries += 1
        puts "\nTimed Out. Trying again...\n"
        system(cmd)
      end

      success &&= $?.success?
    end

    Process.kill(:SIGINT, server)
    Process.wait

    if success
      puts "\nTests Passed".green
    else
      puts "\nTests Failed".red
      exit(1)
    end
  end

  desc "Automatically run tests (Mac OS X only)"
  task :autotest do
    system("kicker -e 'rake test' packages")
  end
end
