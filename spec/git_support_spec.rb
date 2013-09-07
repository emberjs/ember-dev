require 'tmpdir'
require 'minitest/autorun'

require_relative '../lib/ember-dev/git_support'

describe EmberDev::GitSupport do
  before do
    @tmpdir = Dir.mktmpdir
    at_exit{ FileUtils.remove_entry @tmpdir }
  end

  def copy_repo(from, to = @tmpdir)
    new_path = File.join(to, File.basename(from))

    FileUtils.cp_r from, new_path

    new_path
  end

  def in_repo_dir(path)
    Dir.chdir path do
      yield
    end
  end

  def commits_for_repo(path)
    in_repo_dir path do
      `git rev-list HEAD`.to_s.split("\n")
    end
  end

  let(:tmpdir) { @tmpdir }
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
end
