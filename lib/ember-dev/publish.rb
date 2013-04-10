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
        filename = file.split('.js').first.split('/').last
        minified_files = []
        unminified_files = []
        unminified_files << bucket.objects["#{filename}-latest.js"]
        unminified_files << bucket.objects["#{filename}-#{rev}.js"]
        minified_files << bucket.objects["#{filename}-latest.min.js"]
        minified_files << bucket.objects["#{filename}-#{rev}.min.js"]
        unminified_files.each { |obj| obj.write Pathname.new file }
        minified_files.each { |obj|
          obj.write Pathname.new file.sub("/#{filename}.js$", filename + '.min.js')
        }
      end
    end

  end
end

