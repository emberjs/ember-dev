require 'minitest/autorun'

require_relative '../support/tmpdir_helpers'
require_relative '../support/integration_helpers'

describe "Can run the static site test suite" do
  include TmpdirHelpers
  include IntegrationHelpers

  before do
    with_clean_env do
      override_gemfile

      assert system("npm install defeatureify")
      assert system("bundle update ember-dev")
      assert system("RUBYOPT='-r#{@original_working_directory}/lib/ember-dev' rake ember:generate_static_test_site")
    end
  end

  let(:javascript_test_path) { "#{@original_working_directory}/support/tests" }
  let(:phantom_path) { 'phantomjs' }

  describe "for emberjs/ember.js" do
    let(:project_path) { File.join(tmpdir, 'ember.js') }
    let(:project_git_url) { "https://github.com/emberjs/ember.js.git" }

    it "passes tests" do
      command = "#{phantom_path} #{javascript_test_path}/qunit/run-qunit.js \"dist/ember-tests.html\""
      assert system(command)
    end
  end
end
