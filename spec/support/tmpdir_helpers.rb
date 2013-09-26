require 'tmpdir'

module TmpdirHelpers
  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry tmpdir
  end
end

