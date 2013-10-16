module EmberDev
  class VersionCalculator
    attr_accessor :debug, :git_support, :version_file_contents

    def initialize(options = nil)
      options ||= {}

      self.debug                 = options.fetch(:debug, false)
      self.git_support           = options.fetch(:git_support) { GitSupport.new('.', debug: debug) }
      self.version_file_contents = options.fetch(:version_file_contents, nil)
    end

    def version_file_contents
      @version_file_contents ||= read_file_contents
    end

    def contains_metadata_tag?
      version_file_contents =~ /\+/
    end

    def short_revision
      revision[0,8]
    end

    def revision
      git_support.current_revision
    end

    def version
      return version_file_contents unless contains_metadata_tag?

      "#{version_file_contents}.#{short_revision}"
    end

    private

    def read_file_contents
      File.read('VERSION').gsub(/\s/,'')
    end
  end
end
