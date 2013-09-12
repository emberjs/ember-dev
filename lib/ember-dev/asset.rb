require 'pathname'
require_relative 'publish'

module EmberDev
  module Publish
    class Asset
      attr_accessor :file, :current_revision, :current_tag,
                    :build_type, :tags_only, :ignore_missing_files

      def initialize(filename, options = nil)
        options              ||= {}

        self.file                 = Pathname.new(filename)
        self.current_revision     = options.fetch(:revision) { EmberDev::Publish.current_revision }
        self.current_tag          = options.fetch(:tag)      { EmberDev::Publish.current_tag }
        self.build_type           = options.fetch(:build_type)   { :canary }
        self.tags_only            = options.fetch(:tags_only) { false }
        self.ignore_missing_files = options.fetch(:ignore_missing_files) { false }
      end

      def basename
        file.basename.sub_ext('')
      end

      def extension
        file.extname
      end

      def unminified_source
        file
      end

      def has_tag
        current_tag.to_s != ''
      end

      def targets_for(extension)
        targets = []
        prefix  = ''

        case build_type
        when :canary
          prefix  = 'canary/'
          targets << "#{basename}-latest#{extension}"
          targets << "latest/#{basename}#{extension}"
        when :beta
          prefix  = 'beta/'
        when :release
          prefix  = 'release/'
          targets << "stable/#{basename}#{extension}"
        end

        targets << "#{prefix}#{basename}#{extension}"
        targets << "#{prefix}daily/#{Date.today.strftime('%Y%m%d')}/#{basename}#{extension}"
        targets << "#{prefix}shas/#{current_revision}/#{basename}#{extension}"

        targets = [] if tags_only

        targets << "tags/#{current_tag}/#{basename}#{extension}" if has_tag

        targets.compact
      end

      def unminified_targets
        targets_for(extension)
      end

      def minified_source
        file.sub_ext('.min' + extension)
      end

      def minified_targets
        targets_for('.min' + extension)
      end

      def production_source
        file.sub_ext('.prod' + extension)
      end

      def production_targets
        targets_for('.prod' + extension)
      end

      def files_for_publishing
        strip_missing_files unminified_source => unminified_targets,
                            minified_source   => minified_targets,
                            production_source => production_targets
      end

      private

      def strip_missing_files(hash)
        return hash if ignore_missing_files

        hash.keys.each do |path|
          hash.delete(path) unless File.exists?(path)
        end

        hash
      end
    end
  end
end
