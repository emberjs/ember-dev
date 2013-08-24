require 'aws-sdk'
require 'zlib'

module EmberDev
  module Publish

    def self.to_s3(opts={})
      files = opts.fetch(:files)
      bucket_name = opts.fetch(:bucket_name)
      access_key_id = opts.fetch(:access_key_id)
      secret_access_key = opts.fetch(:secret_access_key)
      excluded_minified_files = opts[:exclude_minified] || []

      subdirectory = opts[:subdirectory] ? opts[:subdirectory] + '/' : ''

      rev = `git rev-list HEAD -n 1`.to_s.strip

      master_rev = `git rev-list origin/master -n 1`.to_s.strip

      return unless rev == master_rev
      return unless access_key_id && secret_access_key && bucket_name

      s3 = AWS::S3.new(
        :access_key_id     =>  access_key_id,
        :secret_access_key => secret_access_key)

      bucket = s3.buckets[bucket_name]

      s3_options = {
        :content_type     => 'text/javascript',
      }

      files.each do |file|
        basename = Pathname.new(file).basename.sub_ext('')

        unminified_targets = [
          "#{basename}-latest.js",
          "#{basename}-#{rev}.js"
        ].map do |f|
          bucket.objects[subdirectory + f]
        end

        unminified_targets.each do |obj|
          obj.write(file, s3_options)
        end

        minified_source = file.sub(/#{basename}.js$/, "#{basename}.min.js")

        minified_targets = [
          "#{basename}-latest.min.js",
          "#{basename}-#{rev}.min.js"
        ].map do |f|
          bucket.objects[subdirectory + f]
        end

        unless excluded_minified_files.include?(file)
          minified_targets.each do |obj|
            obj.write(Pathname.new(minified_source), s3_options)
          end
        end

        prod = bucket.objects["#{subdirectory}#{basename}.prod.js"]
        prod.write gzip(file.sub(/#{basename}.js$/, "#{basename}.prod.js")), s3_options
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

