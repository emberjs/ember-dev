namespace :ember do
  desc "Run tests with phantomjs"
  task :test, [:suite] => :dist do |t, args|
    unless sh("which phantomjs > /dev/null 2>&1")
      abort "PhantomJS is not installed. Download from http://phantomjs.org"
    end

    test_support = EmberDev::TestSupport.new(:selected_suite => args[:suite])

    unless test_support.test_runs
      abort "No suite named: #{test_support.selected_suite}"
    end

    success = test_support.run_all

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
