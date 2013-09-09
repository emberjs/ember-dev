module TmpdirHelpers
  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  def setup
    @tmpdir = Dir.mktmpdir
    at_exit{ FileUtils.remove_entry @tmpdir }
  end
end

