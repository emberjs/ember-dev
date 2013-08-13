require 'pathname'
require_relative 'publish'

module EmberDev
  module Publish
    class Asset
      attr_accessor :file, :current_revision

      def initialize(filename, current_revision = EmberDev::Publish.current_revision)
        self.file             = Pathname.new(filename)
        self.current_revision = current_revision
      end

      def basename
        file.basename.sub_ext('')
      end

      def unminified_source
        file
      end

      def unminified_targets
        ["latest/#{basename}.js",
         "shas/#{current_revision}/#{basename}.js"]
      end

      def minified_source
        file.sub_ext('.min.js')
      end

      def minified_targets
        ["latest/#{basename}.min.js",
         "shas/#{current_revision}/#{basename}.min.js"]
      end

      def production_source
        file.sub_ext('.prod.js')
      end

      def production_targets
        ["latest/#{basename}.prod.js",
         "shas/#{current_revision}/#{basename}.prod.js"]
      end

      def files_for_publishing
        { unminified_source => unminified_targets,
          minified_source   => minified_targets,
          production_source => production_targets }
      end
    end
  end
end
