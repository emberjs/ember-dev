require 'pathname'

module EmberDev
  class GitSupport
    attr_accessor :repo_path

    def initialize(repo_path = '.', options = {})
      self.repo_path = Pathname.new(repo_path)

      @use_travis_environment_variables = options.fetch(:use_travis_environment_variables) { true }
    end

    def use_travis_environment_variables
      @use_travis_environment_variables && ENV['TRAVIS']
    end

    def current_tag
      git_command "git tag --points-at #{current_revision}"
    end

    def current_revision
      if use_travis_environment_variables
        ENV['TRAVIS_COMMIT']
      else
        git_command("git rev-list HEAD -n 1")
      end
    end

    def current_branch
      if use_travis_environment_variables
        ENV['TRAVIS_BRANCH']
      else
        branches_containing_commit.first
      end
    end

    def make_shallow_clone_into_full_clone
      git_command 'git fetch --quiet --unshallow'
    end

    private

    def branches_containing_commit(commit = current_revision)
      git_command("git branch --all --contains #{current_revision}")
        .split("\n")
        .reject{|r| r =~ /detached/ } # get rid of any entries for detached head
        .collect{|r| r.gsub(/\W/, '') }
    end

    def git_command(command_to_run)
      Dir.chdir(repo_path) do
        `#{command_to_run}`.to_s.strip
      end
    end
  end
end
