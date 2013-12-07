namespace :ember do
  desc "Run tests with phantomjs"
  task :test, [:suite] => :dist do |t, args|
    unless sh("phantomjs --version > /dev/null 2>&1")
      abort "PhantomJS is not installed. Download from http://phantomjs.org"
    end

    params = {}
    params[:selected_suite] = args[:suite] if args[:suite]

    if ENV['MULTI_BRANCH_TESTS'] || ENV['TRAVIS_PULL_REQUEST']
      params[:enable_multi_branch_tests] = true
    end

    if ENV['FORCE_BRANCH']
      params[:force_branch] = ENV['FORCE_BRANCH']
    end

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

  desc "Generate a static test site."
  task :generate_static_test_site => :dist do
    generator = EmberDev::TestSiteGenerator.new(static: true)

    generator.save("dist/#{EmberDev.config.dasherized_name}-tests.html")
  end

  desc "Automatically run tests (Mac OS X only)"
  task :autotest do
    sh("kicker -e 'rake test' packages")
  end
end
