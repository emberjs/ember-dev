def pipeline
  require 'rake-pipeline'
  Rake::Pipeline::Project.new(File.expand_path("../../ember-dev/assetfile.rb", __FILE__))
end

namespace :ember do
  desc "Build ember.js"
  task :dist do
    puts "Building Ember..."
    pipeline.invoke
    puts "Done"
  end

  desc "Clean build artifacts from previous builds"
  task :clean do
    puts "Cleaning build..."
    rm_rf "dist" # Make sure even things RakeP doesn't know about are cleaned
    rm_f "tests/ember-tests.js"
    rm_rf "tmp"
    puts "Done"
  end

  desc "Build Ember.js from a given fork & branch"
  task :build, :username, :branch do |t, args|
    require "grit"

    if args.to_hash.keys.length != 2
      puts "Usage: rake build[wycats,some-cool-feature]"
      exit 1
    end

    username, branch = args[:username], args[:branch]

    remote_path = "https://github.com/#{username}/ember.js.git"

    repo = Grit::Repo.new(File.dirname(File.expand_path(__FILE__)))

    unless repo.remotes.map(&:name).grep(/#{username}/).length == 0
      repo.remote_add(username, remote_path)
    end

    repo.remote_fetch username

    `git checkout -B testing-#{username}-#{branch} master`
    `git merge #{username}/#{branch}`

    puts "Resolve possible merge conflicts and run `rake dist`"
  end
end
