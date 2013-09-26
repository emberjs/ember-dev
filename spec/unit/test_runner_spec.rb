require 'net/http'
require 'minitest/autorun'

require_relative '../../lib/ember-dev'

describe EmberDev::TestRunner do
  describe "running server thread" do
    after do
      EmberDev::TestRunner.stop_server
    end

    it "spawns the server thread" do
      EmberDev::TestRunner.start_server
      EmberDev::TestRunner.wait_for_server

      http = Net::HTTP.new("localhost", 60099)
      response = http.request(Net::HTTP::Get.new("/foo/bar"))

      assert_equal 'Hello world', response.body
    end
  end

  describe "the port used for the rack server" do
    after do
      ENV.delete('TEST_SERVER_PORT')
    end

    it "defaults to port 60099" do
      assert_equal 60099, EmberDev::TestRunner.server_port
    end

    it "will use ENV['TEST_SERVER_PORT'] if present" do
      ENV['TEST_SERVER_PORT'] = "5555"

      assert_equal "5555", EmberDev::TestRunner.server_port
    end
  end

  describe "generates runnable test commands" do
    it "uses the phantom_path" do
      runner = EmberDev::TestRunner.new('blah', :phantom_path => 'boomcity/phantomjs')

      assert runner.test_command.start_with?('boomcity/phantomjs')
    end

    it "uses the test_params" do
      runner = EmberDev::TestRunner.new('blah', :phantom_path => 'boomcity/phantomjs')

      assert runner.test_command.end_with?('blah"'), 'test_command does not include the provide test_params'
    end
  end

  it "returns the path to the javascript tests" do
    runner = EmberDev::TestRunner.new('blah')

    assert File.exist?(runner.javascript_test_path)
  end

  describe "knows the phantomjs command to run" do
    it "defaults to 'phantomjs'" do
      runner = EmberDev::TestRunner.new('blah')

      assert_equal 'phantomjs', runner.phantom_path
    end

    it "can be provided as an option" do
      runner = EmberDev::TestRunner.new('blah', :phantom_path => 'boomcity/phantomjs')

      assert_equal 'boomcity/phantomjs', runner.phantom_path
    end
  end
end
