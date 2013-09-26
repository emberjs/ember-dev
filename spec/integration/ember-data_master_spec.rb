require 'minitest/autorun'

require_relative '../support/tmpdir_helpers'
require_relative '../support/integration_helpers'

describe "Can run the full ember-data test suite" do
  include TmpdirHelpers
  include IntegrationHelpers

  let(:project_path) { File.join(tmpdir, 'ember-data') }
  let(:project_git_url) { "https://github.com/emberjs/data.git" }

  it "should be able to run the full ember.js test suite" do
    with_clean_env do
      override_gemfile

      assert system("bundle update ember-dev")
      assert system("RUBYOPT='-r#{@original_working_directory}/lib/ember-dev' rake test\\[all]")
    end
  end
end

