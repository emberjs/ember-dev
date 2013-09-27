require 'pathname'

module EmberDev
  class GitSupport
    attr_accessor :repo_path

    def initialize(repo_path = '.', options = {})
      self.repo_path = Pathname.new(repo_path).realpath
      @env           = options.fetch(:env) { ENV }
      @debug         = options.fetch(:debug) { false }
      @git_version   = git_command('git --version')
      @use_travis_environment_variables = options.fetch(:use_travis_environment_variables) { true }

      print_debugging_info if @debug
    end

    def print_debugging_info
      puts "Git Support Debugging Info:"
      puts "  commit_range: #{commit_range}"
      puts "  current_tag: #{current_tag}"
      puts "  current_branch: #{current_branch}"
      puts "  current_revision: #{current_revision}"
      puts "  commits: #{commits}"
    end

    def use_travis_environment_variables
      @use_travis_environment_variables &&
        @env['TRAVIS'] &&
        @env['TRAVIS_BUILD_DIR'] == repo_path.to_s
    end

    def current_tag
      git_command "git tag --points-at #{current_revision}"
    end

    def current_revision
      if use_travis_environment_variables
        @env['TRAVIS_COMMIT']
      else
        git_command("git rev-list HEAD -n 1")
      end
    end

    def current_branch
      if use_travis_environment_variables
        @env['TRAVIS_BRANCH']
      else
        branches_containing_commit.first
      end
    end

    def make_shallow_clone_into_full_clone
      git_command 'git fetch --quiet --unshallow'
    end

    def commit_range
      if use_travis_environment_variables
        @env['TRAVIS_COMMIT_RANGE']
      else
        current_revision + '...master'
      end
    end

    def checkout(branch)
      git_command "git checkout --quiet #{branch}"
    end

    def commits
      Hash[git_command("git log --no-abbrev-commit --pretty=oneline #{commit_range}")
        .split("\n")
        .collect{|c| c.split(' ',2) }]
    end

    def cherry_pick(sha)
      existing_commits = git_command("git rev-list --max-count=50 HEAD")
      return true if existing_commits.include?(sha)

      git_command("git cherry-pick -x #{sha}")

      $?.success?
    end

    private

    def branches_containing_commit(commit = current_revision)
      git_command("git branch --all --contains #{current_revision}")
        .split("\n")
        .reject{|r| r =~ /detached/ } # get rid of any entries for detached head
        .collect{|r| r.gsub(/\W/, '') }
    end

    def git_command(command_to_run)
      result =  Dir.chdir(repo_path) do
                  `#{command_to_run}`.to_s.strip
                end

      unless $?.success?
        puts "The git command failed: '#{command_to_run}'\n"
        puts "  Using git version: #{@git_version}"
        puts "  Call stack: ", *caller.map{|s| "    #{s}" }
        puts "  Result:", *result.split("\n").map{|s| "    #{s}" }
      end

      result
    end
  end
end
