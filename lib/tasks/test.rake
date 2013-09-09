namespace :ember do
  desc "Run tests with phantomjs"
  task :test, [:suite] => :dist do |t, args|
    unless sh("which phantomjs > /dev/null 2>&1")
      abort "PhantomJS is not installed. Download from http://phantomjs.org"
    end

    params = {}
    params[:selected_suite] = args[:suite] if args[:suite]

    test_support = EmberDev::TestSupport.new(params)

    unless test_support.test_runs
      abort "No suite named: #{test_support.selected_suite}"
    end

    if test_support.run_all
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
