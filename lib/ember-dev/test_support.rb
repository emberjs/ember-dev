module EmberDev
  class TestSupport
    attr_reader :selected_suite, :git_support, :debug

    def initialize(options = {})
      @packages       = options.fetch(:packages)         { nil }
      @suites         = options.fetch(:suites)           { nil }
      @debug          = options.fetch(:debug)            { true }
      @selected_suite = options.fetch(:selected_suite)   { 'default' }
      @git_support    = options.fetch(:git_support)      { GitSupport.new('.', :debug => @debug) }
      @force_branch   = options.fetch(:force_branch)     { nil }
      @multi_branch   = options.fetch(:enable_multi_branch_tests) { false }
    end

    def packages
      @packages ||= Dir['packages/*/tests'].sort.map { |p| p.split('/')[1] }
    end

    def suites
      @suites ||= build_suites
    end

    def test_runs(suite = selected_suite)
      ENV['TEST'] ? [ENV['TEST']] : suites[suite]
    end

    def run_all
      if @force_branch
        if branches_to_test.include?(@force_branch)
          return prepare_for_branch_tests(@force_branch) && run_all_tests_on_current_revision
        else
          puts "No commits for #{@force_branch}." if debug
          return true
        end
      end

      puts "Running tests on #{git_support.current_branch}" if debug
      return false unless run_all_tests_on_current_revision
      return true unless @multi_branch

      branches_to_test.all? do |branch|
        prepare_for_branch_tests(branch) && run_all_tests_on_current_revision
      end
    end

    def prepare_for_branch_tests(branch)
      git_support.make_shallow_clone_into_full_clone

      puts "Checking out: #{branch}" if debug
      return false unless git_support.checkout(branch)

      return false unless commits_by_branch[branch].all? do |commit|
        puts "Cherry picking #{commit} into #{branch}" if debug
        git_support.cherry_pick(commit)
      end

      build
    end

    def build
      Bundler.with_clean_env do
        backtick("bundle install && bundle exec rake ember:dist")
      end

      $?.success?
    end

    def run_all_tests_on_current_revision
      success = false

      EmberDev::TestRunner.with_server do
        success = test_runs.all? do |run_params|
          EmberDev::TestRunner.run(run_params)
        end
      end

      success
    end

    def branches_to_test
      commits_by_branch.keys
    end

    def commits_by_branch
      return @commits_by_branch if @commits_by_branch

      ret = Hash.new{|h,k| h[k] = []}

      git_support.commits.each do |sha, message|
        case message
        when /\[BUGFIX beta\]/, /\[DOC beta\]/
          ret['beta'] << sha
        when /\[BUGFIX release\]/, /\[DOC release\]/
          ret['beta'] << sha
          ret['stable'] << sha
        when /\[SECURITY\]/
          ret['beta'] << sha
          ret['stable'] << sha
        end
      end

      @commits_by_branch = ret
    end

    private

    def build_suites
      suites = build_suite_for_each_package
      suites['default'] = ['EACH_PACKAGE']

      if EmberDev.config.testing_suites
        suites.merge!(EmberDev.config.testing_suites)
      end

      # This is a bit of a hack
      suites.each do |name, opts|
        if idx = opts.index('EACH_PACKAGE')
          opts[idx] = each_package_test_runs
          opts.flatten!
        end
      end

      suites
    end

    def build_suite_for_each_package
      Hash[packages.collect do |package|
        [package, ["package=#{package}"]]
      end]
    end

    def each_package_test_runs
      output = []

      packages.each do |package|
        output << "package=#{package}"

        output << "package=#{package}&enableoptionalfeatures=true"
      end

      output
    end

    def backtick(command)
      puts "Running: #{command}"
      puts `#{command}`
    end
  end
end
