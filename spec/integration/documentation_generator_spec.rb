require 'rake'
require 'tmpdir'
require 'fileutils'
require 'minitest/autorun'

require_relative '../support/tmpdir_helpers'
require_relative '../support/integration_helpers'

describe "Can generate the appropriate YUIDocs" do
  include TmpdirHelpers
  include IntegrationHelpers

  let(:project_path) { File.join(tmpdir, 'ember-data') }
  let(:project_git_url) { "https://github.com/emberjs/data.git" }

  it "should be able to run the full ember.js test suite" do
    with_clean_env do
      override_gemfile

      assert system("bundle update ember-dev")
      assert system("rake ember:docs")

      generated_docs = File.read('docs/build/data.json')

      FileUtils.rm_rf 'docs/build'

      Dir.chdir 'docs' do
        system('yuidoc -p -q')
      end

      assert_equal File.read('docs/build/data.json'), generated_docs
    end
  end
end

