require 'aws-sdk'

module EmberDev
  module Publish

    def self.to_s3(opts={})
      files = opts.fetch(:files)
      bucket_name = opts.fetch(:bucket_name)
      access_key_id = opts.fetch(:access_key_id)
      secret_access_key = opts.fetch(:secret_access_key)

      subdirectory = opts[:subdirectory] ? opts[:subdirectory] + '/' : ''

      rev = `git rev-list HEAD -n 1`.to_s.strip

      master_rev = `git rev-list origin/master -n 1`.to_s.strip

      return unless rev == master_rev
      return unless access_key_id && secret_access_key && bucket_name

      s3 = AWS::S3.new(
        access_key_id: access_key_id,
        secret_access_key: secret_access_key)

      bucket = s3.buckets[bucket_name]

      files.each do |file|
        basename = Pathname.new(file).basename.sub_ext('')

        unminified_targets = [
          "#{basename}-latest.js",
          "#{basename}-#{rev}.js"
        ].map do |file|
          bucket.objects[subdirectory + file]
        end

        unminified_targets.each do |obj|
          obj.write(Pathname.new(file))
        end

        minified_source = file.sub(/#{basename}.js$/, "#{basename}.min.js")

        minified_targets = [
          "#{basename}-latest.min.js",
          "#{basename}-#{rev}.min.js"
        ].map do |file|
          bucket.objects[subdirectory + file]
        end

        prod = bucket.objects["#{subdirectory}#{basename}.prod.js"]
        prod.write Pathname.new file.sub(/#{basename}.js$/, "#{basename}.prod.js")

        minified_targets.each do |obj|
          obj.write(Pathname.new(minified_source))
        end
      end
    end
  end
end

