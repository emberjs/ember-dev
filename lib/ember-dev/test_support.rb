module EmberDev
  class TestSupport
    attr_reader :selected_suite

    def initialize(options = {})
      @packages       = options.fetch(:packages)         { nil }
      @suites         = options.fetch(:suites)           { nil }
      @selected_suite = options.fetch(:selected_suite)   { 'default' }
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
      success = false

      EmberDev::TestRunner.with_server do
        success = test_runs.all? do |run_params|
          EmberDev::TestRunner.run(run_params)
        end
      end

      success
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
