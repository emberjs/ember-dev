require 'minitest/autorun'

require_relative '../../lib/ember-dev/git_support'
require_relative '../support/tmpdir_helpers'
require_relative '../support/repo_helpers'

describe EmberDev::GitSupport do
  include TmpdirHelpers
  include RepoHelpers

  let(:standard_repo) { Pathname.new('spec/support/test_repos/standard_repo') }
  let(:standard_repo_on_branch) { Pathname.new('spec/support/test_repos/standard_repo_on_branch') }

  let(:git_support) { EmberDev::GitSupport.new(repo_path, :use_travis_environment_variables => false) }

  describe "Working on master branch with tag at HEAD" do
    let(:repo_path)   { standard_repo }

    it "knows what the current branch is" do
      assert_equal 'master', git_support.current_branch
    end

    it "knows what the current tag is" do
      assert_equal "rubble", git_support.current_tag
    end

    it "knows what the current revision is" do
      assert_equal commits_for_repo(repo_path).first, git_support.current_revision
    end
  end

  describe "Working on different branch without a tag" do
    let(:repo_path)   { standard_repo_on_branch }

    it "knows what the current branch is" do
      assert_equal 'barney', git_support.current_branch
    end

    it "knows that there is no tag" do
      assert_equal '', git_support.current_tag
    end

    it "knows what the current revision is" do
      assert_equal commits_for_repo(repo_path).first, git_support.current_revision
    end
  end

  describe "Knows which branch we are working on in detached mode" do
    let(:repo_path)   { @tmp_repo_path }
    let(:repo_commits) { commits_for_repo(standard_repo_on_branch) }

    before do
      @tmp_repo_path = copy_repo(standard_repo_on_branch)
    end

    it "knows what the current branch is when it only belongs to one branch" do
      commit = repo_commits.first

      in_repo_dir repo_path do
        `git checkout -qf #{commit}`
      end

      assert_equal 'barney', git_support.current_branch
    end

    it "gives preference to the last checked out branch if commit exists in multiple" do
      commit = repo_commits.last

      in_repo_dir repo_path do
        `git checkout -qf #{commit}`
      end

      assert_equal 'barney', git_support.current_branch
    end
  end

  describe "Can turn a shallow clone into a full clone" do
    let(:shallow_clone_path) { tmpdir + '/shallow_clone' }
    let(:repo_path) { shallow_clone_path }

    let(:base_repo_commits) { commits_for_repo(standard_repo) }
    let(:shallow_clone_commits) {commits_for_repo(shallow_clone_path) }

    before do
      `git clone --quiet --depth=1 file://#{standard_repo.realpath} #{shallow_clone_path}`
    end

    it "the initial shallow_clone should only have one commit to start with" do
      assert base_repo_commits.length > 1, 'the base repo must have more than one commit'
      assert_equal 1, shallow_clone_commits.length
    end

    it "can unshallowify a repo" do
      assert_equal 1, commits_for_repo(git_support.repo_path).length

      git_support.make_shallow_clone_into_full_clone

      assert_equal base_repo_commits, commits_for_repo(git_support.repo_path)
    end
  end

  describe "listing commits since master" do
    let(:repo_path) { standard_repo_on_branch }

    it "should return the commit SHA's and their commit messages" do
      expected_response = { "2956fa9116bfcf7b54b5bd73c2e656747f528381" => "Add wilma.",
                            "3ab485e06fcfae8949b065ad0dfaefeba5828fb1" => "Added blammo.",
                            "397b98770c3e742298500795cc632d2a1100e2e3" => "Added blahzorz."}
      initial_git_response = expected_response.map{|k,v| "#{k} #{v}"}.join("\n")

      git_support.stub :git_command, initial_git_response do
        assert_equal expected_response, git_support.commits
      end
    end
  end

  describe "the range of commits since master" do
    let(:repo_path) { standard_repo_on_branch }

    it "should use the TRAVIS_COMMIT_RANGE variable if present" do
      env = {'TRAVIS' => 'true', 'TRAVIS_COMMIT_RANGE' => 'blardyblarblar'}

      git_support = EmberDev::GitSupport.new(repo_path, :env => env)

      assert_equal 'blardyblarblar', git_support.commit_range
    end

    it "should return a string representing the range from the current commit to master" do
      expected_result = git_support.current_revision + '...master'

     assert_equal expected_result, git_support.commit_range
    end
  end

  describe "can checkout another branch" do
    let(:repo_path) { tmpdir + '/clone_path' }

    before do
      `git clone --quiet file://#{standard_repo_on_branch.realpath} #{repo_path}`
    end

    it "can checkout the master branch" do
      base_repo_commits = commits_for_repo(standard_repo)

      git_support.checkout('master')

      assert_equal base_repo_commits, commits_for_repo(repo_path)
    end
  end

  describe 'can cherry-pick commits by sha' do
    let(:repo_path) { tmpdir + '/clone_path' }
    let(:master_commits) { commits_for_repo(standard_repo) }
    let(:barney_commits) { commits_for_repo(standard_repo_on_branch) }
    let(:cherry_picked_sha) { barney_commits.first }

    before do
      `git clone --quiet file://#{standard_repo_on_branch.realpath} #{repo_path}`

      in_repo_dir repo_path do
        `git config user.email "test@example.com"`
        `git config user.name "Test User"`
      end

      git_support.checkout('master')
      assert_equal master_commits, commits_for_repo(repo_path)
    end


    it "returns true if the commit is already in the current branch" do
      assert git_support.cherry_pick(barney_commits.first)
    end

    it "adds the changes from the specified <SHA> to the current branch" do
      git_support.cherry_pick(cherry_picked_sha)

      in_repo_dir repo_path do
        assert `git log --grep="#{cherry_picked_sha}"`.include?(cherry_picked_sha)
      end

      assert `diff --exclude '.git' #{standard_repo_on_branch} #{repo_path}`.empty?
    end

    it "returns false if the commit cannot be cleanly merged" do
      in_repo_dir repo_path do
        FileUtils.touch('wilma')
      end

      refute git_support.cherry_pick(cherry_picked_sha)
    end
  end
end
