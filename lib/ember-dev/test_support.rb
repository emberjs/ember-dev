module EmberDev
  class TestSupport
    attr_reader :selected_suite, :git_support, :debug

    def initialize(options = {})
      @packages       = options.fetch(:packages)         { nil }
      @suites         = options.fetch(:suites)           { nil }
      @debug          = options.fetch(:debug)            { true }
      @selected_suite = options.fetch(:selected_suite)   { 'default' }
      @git_support    = options.fetch(:git_support)      { GitSupport.new('.', :debug => @debug) }
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
      puts 'Running tests on master' if debug
      return false unless run_all_tests_on_current_revision

      branches_to_test.all? do |branch|
        prepare_for_branch_tests(branch) && run_all_tests_on_current_revision
      end
    end

    def prepare_for_branch_tests(branch)
      git_support.make_shallow_clone_into_full_clone

      puts "Checking out: #{branch}" if debug
      return false unless git_support.checkout(branch)

      commits_by_branch[branch].all? do |commit|
        puts "Cherry picking #{commit} into #{branch}" if debug
        git_support.cherry_pick(commit)
      end
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
      ret = Hash.new{|h,k| h[k] = []}

      git_support.commits.each do |sha, message|
        case message
        when /\[BUGFIX beta\]/
          ret['beta'] << sha
        when /\[BUGFIX release\]/
          ret['beta'] << sha
          ret['stable'] << sha
        when /\[SECURITY\]/
          ret['beta'] << sha
          ret['stable'] << sha
        end
      end

      ret
    end

    private

    def build_suites
      suites = build_suite_for_each_package
      suites['default'] = packages.map{|p| "package=#{p}"}

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

      suites
    end

    def build_suite_for_each_package
      Hash[packages.collect do |package|
        [package, ["package=#{package}"]]
      end]
    end

  end
end
