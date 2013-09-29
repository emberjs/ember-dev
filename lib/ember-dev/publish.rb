require 'aws-sdk'
require 'zlib'

require_relative 'asset'
require_relative 'git_support'
require_relative 'channel_releases_file_generator'

module EmberDev
  module Publish

    def self.repo
      @repo ||= GitSupport.new '.', :debug => false
    end
    private_class_method :repo

    def self.current_tag
      repo.current_tag
    end

    def self.current_revision
      repo.current_revision
    end

    def self.current_branch
      repo.current_branch
    end

    def self.build_type
      case current_branch
      when 'stable','release' then :release
      when 'beta'             then :beta
      when 'master'           then :canary
      end
    end

    def self.debug_information
      puts 'Publish Debugging Information: '
      travis_vars = %w{TRAVIS_BRANCH TRAVIS_COMMIT TRAVIS_COMMIT_RANGE TRAVIS_PULL_REQUEST TRAVIS_SECURE_ENV_VARS}
      travis_vars.each do |variable_name|
        puts "  #{variable_name}: '#{ENV[variable_name]}'"
      end

      puts "  current_revision: '#{current_revision}'"
      puts "  current_branch: '#{current_branch}'"
      puts "  current_tag: '#{current_tag}'"
      puts "  build_type: '#{build_type}'"
    end

    def self.to_s3(opts={})
      files = opts.fetch(:files)
      bucket_name = opts.fetch(:bucket_name)
      access_key_id = opts.fetch(:access_key_id)
      secret_access_key = opts.fetch(:secret_access_key)
      pretend = opts.fetch(:pretend) { ENV['PRETEND'] }
      tags_only = opts.fetch(:tags_only) { ENV['TAGS_ONLY'] }

      subdirectory = opts[:subdirectory] ? opts[:subdirectory] + '/' : ''

      debug_information

      if build_type.nil?
        puts "Not building release, beta, or canary branches. No assets will be published."
        return
      end

      unless pretend || access_key_id && secret_access_key && bucket_name
        puts "No AWS values were available. No assets will be published."
        return
      end

      unless pretend
        @s3 = AWS::S3.new(
          :access_key_id     =>  access_key_id,
          :secret_access_key => secret_access_key)

        @bucket = @s3.buckets[bucket_name]

        @s3_options = {
          :content_type     => 'text/javascript',
        }

        generator = ChannelReleasesFileGenerator.new

        if generator.should_generate?
          obj = @bucket.objects[generator.destination_path]
          obj.write(generator.to_json, {:content_type => 'application/json'})
        end
      end

      files.each do |file|
        asset_file = Asset.new(file, opts.merge(:build_type => build_type, :tags_only => tags_only))

        asset_file.files_for_publishing.each do |source_file, target_files|
          target_files.each do |target_file|
            puts " Publishing #{source_file} -> #{target_file}"

            unless pretend
              obj = @bucket.objects[subdirectory + target_file]
              obj.write(source_file, @s3_options)
            end
          end
        end
      end
    end

    # returns a pathname to the gzipped version of the file
    def self.gzip(file)
      gzipped_name = file.sub_ext('.js.gz')
      File.open(gzipped_name, 'w') do |f|
        writer = Zlib::GzipWriter.new(f,9)
        writer.write File.read(file)
        writer.close
      end
      Pathname.new(gzipped_name)
    end
  end
end

