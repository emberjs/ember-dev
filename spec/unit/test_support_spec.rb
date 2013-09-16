require 'minitest/autorun'

require_relative '../../lib/ember-dev'

describe EmberDev::TestSupport do
  let(:support) { EmberDev::TestSupport.new(debug: false) }
  let(:packages) { ['fred-flinstone', 'barney-rubble'] }

  describe "package listing" do
    it "listing packages available for test" do
      Dir.chdir 'spec/support/' do
        assert_equal packages.sort, support.packages.sort
      end
    end
  end

  describe 'knows about test suites' do
    let(:fake_packages) { ['foo','bar'] }
    let(:support) { EmberDev::TestSupport.new(debug: false, packages: fake_packages) }

    it "contains 'default'" do
      assert support.suites['default']
    end

    it "builds a suite for each known package" do
      suites = support.suites

      fake_packages.each do |package|
        assert_equal ["package=#{package}"], suites[package]
      end
    end

    it "reads EmberDev.config.testing_suites for additional suites" do
      testing_suites = {'suite1' => ['blah', 'blah'], 'suite2' => ['boo', 'foo']}
      EmberDev.config.testing_suites = testing_suites

      suites = support.suites

      testing_suites.each do |suite_name, runs|
        assert_equal runs, suites[suite_name]
      end
    end

    it "adds each package individually to suites runs if EACH_PACKAGE is found" do
      testing_suites = {'each' => ['EACH_PACKAGE']}
      EmberDev.config.testing_suites = testing_suites

      suites = support.suites

      fake_packages.each do |package|
        assert suites['each'].include?("package=#{package}")
        assert suites['each'].include?("package=#{package}&enableallfeatures=true")
      end
    end
  end

  describe "selected suite" do
    it "defaults to the 'default' suite" do
      fake_suites  = {'default' => 'blah',
                      'all'     => 'blah blah'}
      support = EmberDev::TestSupport.new(debug: false, suites: fake_suites)

      assert_equal support.selected_suite, 'default'

    end
  end

  describe "test runs" do
    let(:fake_suites) {{ 'standard' => ["package=foo","package=bar"]}}
    let(:support) { EmberDev::TestSupport.new(debug: false,
                                              suites: fake_suites,
                                              selected_suite: 'standard')}

    after do
      ENV.delete('TEST')
    end

    it "returns ENV['TEST'] if present regardless of selected_suite" do
      ENV['TEST'] = 'blahzorz'

      assert_equal ['blahzorz'], support.test_runs
    end

    it "returns the run options for the currently selected_suite" do
      assert_equal fake_suites['standard'], support.test_runs
    end
  end

  describe "branches affected" do
    let(:git_support_mock) { Minitest::Mock.new }
    let(:support) { EmberDev::TestSupport.new(debug: false, :git_support => git_support_mock) }

    it "should not contain master" do
      git_support_mock.expect :commits, {'d9afd8d6d5cbe7b' => 'Some commit message here.'}

      refute support.branches_to_test.include?('master')
    end

    it "is based off of commits_by_branch" do
      support.stub :commits_by_branch, {'some_branch' => 'blah blah'} do
        assert_equal ['some_branch'], support.branches_to_test
      end
    end
  end

  describe "knows which commits are for each branch" do
    let(:git_support_mock) { Minitest::Mock.new }
    let(:support) { EmberDev::TestSupport.new(debug: false, :git_support => git_support_mock) }

    it "should query GitSupport for the commits being tested" do
      git_support_mock.expect :commits, {'d9afd8d6d5cbe7b' => 'Some commit message here.'}

      expected_response = {}

      assert_equal expected_response, support.commits_by_branch
      git_support_mock.verify
    end

    describe "with special commit messages" do
      let(:special_messages_by_branch) do
        { "[BUGFIX beta]" => ['beta'],
          "[BUGFIX release]" => ['beta','stable'],
          "BLAH BLAH [BUGFIX release]" => ['beta','stable'],
          "[DOC beta]" => ['beta'],
          "[DOC release]" => ['beta','stable'],
          "[SECURITY]" => ['beta','stable']
        }
      end

      it "handles the special commit messages properly" do
        special_messages_by_branch.each do |message, branches|
          git_support_mock = Minitest::Mock.new
          support = EmberDev::TestSupport.new(debug: false, :git_support => git_support_mock)

          git_support_mock.expect :commits, {'d9afd8d6d5cbe7b' => "#{message} Some random message."}

          expected_response = Hash[branches.map{|b| [b, ['d9afd8d6d5cbe7b']]}]

          assert_equal expected_response, support.commits_by_branch, "Invalid commits flagged for: #{message}"
          git_support_mock.verify
        end
      end
    end
  end

  describe "prepare to run the tests for the specified branch/commits" do
    let(:git_support_mock) { Minitest::Mock.new }
    let(:support) { EmberDev::TestSupport.new(debug: false, :git_support => git_support_mock) }

    it "calls run_all_test for each branch to test" do
      git_support_mock.expect :commits, {'d9afd8d6d5cbe7b' => '[BUGFIX release] Some random message.'}
      git_support_mock.expect(:checkout, true, ['beta'])
      git_support_mock.expect(:cherry_pick, true, ['d9afd8d6d5cbe7b'])
      git_support_mock.expect(:make_shallow_clone_into_full_clone, true)

      support.prepare_for_branch_tests('beta')

      git_support_mock.verify
    end
  end

  describe "iterates over each branch and runs tests" do
    let(:git_support_mock) { Minitest::Mock.new }
    let(:support) { EmberDev::TestSupport.new(debug: false, :git_support => git_support_mock) }

    before do
      git_support_mock.expect :commits, {'d9afd8d6d5cbe7b' => '[BUGFIX release] Some random message.'}

      # trap and track each call to 'prepare_for_branch_tests'
      def support.prepare_for_branch_tests_calls
        @prepare_calls
      end
      def support.prepare_for_branch_tests(branch)
        @prepare_calls ||= []
        @prepare_calls << branch
      end

      # trap and track each call to 'run_all_tests_on_current_revision'
      def support.run_all_tests_on_current_revision_counter
        @run_all_counter
      end
      def support.run_all_tests_on_current_revision
        @run_all_counter ||= 0
        @run_all_counter +=1
      end
    end

    it "calls run_all_test for each branch to test" do
      support.run_all

      assert_equal 3, support.run_all_tests_on_current_revision_counter
      git_support_mock.verify
    end

    it "calls prepare_for_branch_tests for each additional branch to be tested." do
      support.run_all

      assert_equal ['beta', 'stable'] , support.prepare_for_branch_tests_calls
      git_support_mock.verify
    end

    describe "returns false on any failures" do
      it "if the first run fails" do
        # force the first test run to fail
        def support.run_all_tests_on_current_revision; false; end

        assert_equal false, support.run_all

        assert_equal nil, support.prepare_for_branch_tests_calls
      end

      it "if the second run fails" do
        # force the second test run to fail
        def support.run_all_tests_on_current_revision
          @run_all_counter ||= 0
          @run_all_counter += 1

          @run_all_counter == 2 ? false : true
        end

        assert_equal false, support.run_all

        assert_equal 2, support.run_all_tests_on_current_revision_counter
        assert_equal ['beta'], support.prepare_for_branch_tests_calls
      end

      it "if the first prepare fails" do
        # force the first test run to fail
        def support.prepare_for_branch_tests(b); false; end

        assert_equal false, support.run_all

        assert_equal 1, support.run_all_tests_on_current_revision_counter
      end

      it "if the second prepare fails" do
        # force the first test run to fail
        def support.prepare_for_branch_tests(b)
          @prepare_calls ||= []; @prepare_calls << b;
          b == 'stable' ? false : true
        end

        assert_equal false, support.run_all

        assert_equal 2, support.run_all_tests_on_current_revision_counter
        assert_equal ['beta','stable'], support.prepare_for_branch_tests_calls
      end
    end
  end
end
