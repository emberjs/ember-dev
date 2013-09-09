require_relative 'tmpdir_helpers'

module RepoHelpers
  include TmpdirHelpers

  def copy_repo(from, to = tmpdir)
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
end
