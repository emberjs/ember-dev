require 'pathname'
require_relative 'publish'

module EmberDev
  module Publish
    class Asset
      attr_accessor :file, :current_revision, :current_tag, :stable

      def initialize(filename, options = nil)
        options              ||= {}

        self.file             = Pathname.new(filename)
        self.current_revision = options.fetch(:revision) { EmberDev::Publish.current_revision }
        self.current_tag      = options.fetch(:tag)      { EmberDev::Publish.current_tag }
        self.stable           = options.fetch(:stable)   { false }
      end

      def basename
        file.basename.sub_ext('')
      end

      def unminified_source
        file
      end

      def has_tag
        current_tag.to_s != ''
      end

      def stable
        @stable && @stable.to_s != ''
      end

      def targets_for(extension)
        latest_path   = "latest/#{basename}#{extension}"
        revision_path = "shas/#{current_revision}/#{basename}#{extension}"
        tagged_path   = has_tag ? "tags/#{current_tag}/#{basename}#{extension}" : nil
        stable_path   = stable ? "stable/#{basename}#{extension}" : nil

        [latest_path, revision_path, tagged_path, stable_path].compact
      end

      def unminified_targets
        targets_for('.js')
      end

      def minified_source
        file.sub_ext('.min.js')
      end

      def minified_targets
        targets_for('.min.js')
      end

      def production_source
        file.sub_ext('.prod.js')
      end

      def production_targets
        targets_for('.prod.js')
      end

      def files_for_publishing
        { unminified_source => unminified_targets,
          minified_source   => minified_targets,
          production_source => production_targets }
      end
    end
  end
end
