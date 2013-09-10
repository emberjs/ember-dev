require 'bundler'

module IntegrationHelpers
  def override_gemfile
    gemfile = File.read('Gemfile')
    new_gemfile = gemfile.sub(/^gem ['"]ember-dev['"].*$/, "gem 'ember-dev', :path => '#{@original_working_directory}'")
    File.open('Gemfile', 'w+'){|io| io.write new_gemfile}
  end

  def setup
    @original_working_directory = Dir.getwd

    system("git clone --depth=1 #{project_git_url} #{project_path}")

    Dir.chdir project_path
  end

  def teardown
    Dir.chdir @original_working_directory
  end

  def with_clean_env
    Bundler.with_clean_env do
      yield
    end
  end
end
