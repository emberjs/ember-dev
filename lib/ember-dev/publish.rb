require 'aws-sdk'
require 'zlib'
require_relative 'asset'

module EmberDev
  module Publish

    def self.current_revision
      @current_revision ||= `git rev-list HEAD -n 1`.to_s.strip
    end

    def self.master_revision
      @master_revision ||= `git rev-list origin/master -n 1`.to_s.strip
    end

    def self.to_s3(opts={})
      files = opts.fetch(:files)
      bucket_name = opts.fetch(:bucket_name)
      access_key_id = opts.fetch(:access_key_id)
      secret_access_key = opts.fetch(:secret_access_key)
      excluded_minified_files = opts[:exclude_minified] || []

      subdirectory = opts[:subdirectory] ? opts[:subdirectory] + '/' : ''

      return unless current_revision == master_revision
      return unless access_key_id && secret_access_key && bucket_name

      s3 = AWS::S3.new(
        :access_key_id     =>  access_key_id,
        :secret_access_key => secret_access_key)

      bucket = s3.buckets[bucket_name]

      s3_options = {
        :content_type     => 'text/javascript',
      }

      files.each do |file|
        asset_file = Asset.new(file)

        asset_file.files_for_publishing.each do |source_file, target_files|
          target_files.each do |target_file|
            obj = bucket.objects[subdirectory + target_file]
            obj.write(source_file, s3_options)
          end
        end
      end
    end

    # returns a pathname to the gzipped version of the file
    def self.gzip(file)
      gzipped_name = file + '.gz'
      File.open(gzipped_name, 'w') do |f|
        writer = Zlib::GzipWriter.new(f,9)
        writer.write File.read(file)
        writer.close
      end
      Pathname.new(gzipped_name)
    end
  end
end

