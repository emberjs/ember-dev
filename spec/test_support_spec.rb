require 'minitest/autorun'

require_relative '../lib/ember-dev'

describe EmberDev::TestSupport do
  let(:support) { EmberDev::TestSupport.new }
  let(:packages) { ['fred-flinstone', 'barney-rubble'] }

  describe "package listing" do
    it "listing packages available for test" do
      Dir.chdir 'spec/support/' do
        assert_equal packages.sort, support.packages.sort
      end
    end
  end

  describe 'knows about test suites' do
    it "contains 'default'" do
      assert support.suites['default']
    end

    it "builds a suite for each known package" do
      fake_packages = ['foo','bar']
      support = EmberDev::TestSupport.new(packages: fake_packages)

      suites = support.suites

      fake_packages.each do |package|
        assert_equal ["package=#{package}"], suites[package]
      end
    end
  end

  describe "selected suite" do
    it "defaults to the 'default' suite" do
      fake_suites  = {'default' => 'blah',
                      'all'     => 'blah blah'}
      support = EmberDev::TestSupport.new(suites: fake_suites)

      assert_equal support.selected_suite, 'default'

    end
  end

  describe "test runs" do
    let(:fake_suites) {{ 'standard' => ["package=foo","package=bar"]}}
    let(:support) { EmberDev::TestSupport.new(suites: fake_suites,
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
end
