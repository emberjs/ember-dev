require 'minitest/autorun'

require_relative '../support/repo_helpers'
require_relative '../support/tmpdir_helpers'
require_relative '../support/integration_helpers'

describe "Properly run a multi-branch test." do
  include RepoHelpers
  include TmpdirHelpers
  include IntegrationHelpers

  let(:project_path) { File.join(tmpdir, 'ember.js') }
  let(:project_git_url) { "https://github.com/emberjs/ember.js.git" }

  before do
    in_repo_dir project_path do
      system('git config user.email "test@example.com"')
      system('git config user.name "Test User"')

      system("git branch beta")
      system("git checkout -b fake_branch")
      system("echo 'SOME STRING HERE' >> NEW_UNTRACKED_FILE")
      system("git add NEW_UNTRACKED_FILE")
      system("git commit -m '[BUGFIX beta] Add some new file.'")
    end
  end

  it "should be able to run the full ember.js test suite" do
    with_clean_env do
      override_gemfile

      assert system("npm install defeatureify")
      assert system("bundle update ember-dev")
      assert system("rake test")
    end

    in_repo_dir project_path do
      system("git checkout beta")

      assert_equal "SOME STRING HERE\n", File.read('NEW_UNTRACKED_FILE')
    end
  end
end
