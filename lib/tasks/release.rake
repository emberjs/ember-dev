require 'ember-dev'

namespace :ember do
  namespace :release do
    def pretend?
      ENV['PRETEND']
    end

    def project_version
      VersionCalculator.new.version
    end

    desc "Update repo"
    task :update do
      puts "Making sure repo is up to date..."
      sh("git pull") unless pretend?
    end

    desc "Update Changelog"
    task :changelog do
      last_tag = `git describe --tags --abbrev=0`.strip
      puts "Getting Changes since #{last_tag}"

      cmd = "git log #{last_tag}..HEAD --format='  * %s'"

      changes = `#{cmd}`

      output = "* #{EmberDev.config.name} #{project_version} (#{Time.now.strftime("%B %d, %Y")})*\n\n#{changes}\n"

      unless pretend?
        open('CHANGELOG', 'r+') do |file|
          current = file.read
          file.pos = 0;
          file.puts output
          file.puts current
        end
      else
        puts output.split("\n").map!{|s| "    #{s}"}.join("\n")
      end
    end

    desc "Remove metadata from VERSION"
    task :remove_version_metadata do
      current_version = File.read('VERSION')
      new_version = current_version.sub(/\+.+/,'')

      File.write('VERSION', new_version)
    end

    desc "bump the version to the one specified in the VERSION file"
    task :bump_version, :version do
      puts "Bumping to version: #{project_version}"

      unless pretend?
        # Bump the version of each component package
        Dir["docs/yuidoc.json", "packages/ember*/package.json", "ember.json"].each do |package|
          contents = File.read(package)
          contents.gsub! %r{"version": .*$}, %{"version": "#{project_version}",}
          contents.gsub! %r{"(ember[\w-]*)": [^,\n]+(,)?$} do
            %{"#{$1}": "#{project_version}"#{$2}}
          end

          open(package, "w") { |file| file.write contents }
        end
      end
    end

    desc "Commit framework version bump"
    task :commit do
      puts "Commiting Version Bump"
      unless pretend?
        sh("git reset")
        sh(%{git add VERSION CHANGELOG Gemfile.lock ember.json packages/**/package.json})
        sh("git commit -m 'Version bump - #{project_version}'")
      end
    end

    desc "Tag new version"
    task :tag do
      sh("git tag v#{project_version}") unless pretend?
    end

    desc "Push new commit to git"
    task :push => :dist do
      puts "Pushing Repo"
      unless pretend?
        print "Are you sure you want to push the ember.js repo to github? (y/N) "
        res = STDIN.gets.chomp
        if res =~ /^y/i
          sh("git push")
          sh("git push --tags")
        else
          puts "Not Pushing"
        end
      end
    end

    desc "Prepare for a new release"
    task :prepare => [:update, :remove_version_metadata, :changelog, :bump_version]

    desc "Commit the new release"
    task :deploy => [:commit, :tag, :push] do
      puts "Please make sure to publish the new tagged release to S3.\nEnsure that the S3 credentials in in your ENV and run `rake publish_build`."
    end

    desc "Update versions post release."
    task :after_deploy_version_bump => [:bump_version, :commit, :push]
  end
end
