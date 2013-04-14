module EmberDev
  class Publish
    require 'aws-sdk'

    def self.to_s3(opts={})
      access_key_id = opts.fetch :access_key_id
      secret_access_key = opts.fetch :secret_access_key
      bucket_name = opts.fetch :bucket_name
      files = opts.fetch :files
      rev=`git rev-list HEAD -n 1`.to_s.strip
      master_rev = `git rev-list origin/master -n 1`.to_s.strip
      return unless rev == master_rev
      return unless access_key_id && secret_access_key && bucket_name
      s3 = AWS::S3.new(
        :access_key_id => access_key_id,
        :secret_access_key => secret_access_key)
      bucket = s3.buckets[bucket_name]
      files.each do |file|
        basename = Pathname.new(file).basename.sub_ext('')
        unminified_targets = [
          bucket.objects["#{basename}-latest.js"],
          bucket.objects["#{basename}-#{rev}.js"]
        ]
        unminified_targets.each { |obj| obj.write(Pathname.new(file)) }

        minified_source = file.sub(/#{basename}.js$/, "#{basename}.min.js")
        minified_targets = [
          bucket.objects["#{basename}-latest.min.js"],
          bucket.objects["#{basename}-#{rev}.min.js"]
        ]
        minified_targets.each { |obj| obj.write(Pathname.new(minified_source)) }
      end
    end

  end
end

