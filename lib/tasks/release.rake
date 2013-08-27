PROJECT_VERSION = File.read("VERSION").strip

namespace :ember do
  namespace :release do
    def pretend?
      ENV['PRETEND']
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

      cmd = "git log #{last_tag}..HEAD --format='* %s'"

      changes = `#{cmd}`

      output = "*Ember #{PROJECT_VERSION} (#{Time.now.strftime("%B %d, %Y")})*\n\n#{changes}\n"

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

    desc "bump the version to the one specified in the VERSION file"
    task :bump_version, :version do
      puts "Bumping to version: #{PROJECT_VERSION}"

      unless pretend?
        # Bump the version of each component package
        Dir["packages/ember*/package.json", "ember.json"].each do |package|
          contents = File.read(package)
          contents.gsub! %r{"version": .*$}, %{"version": "#{PROJECT_VERSION}",}
          contents.gsub! %r{"(ember[\w-]*)": [^,\n]+(,)?$} do
            %{"#{$1}": "#{PROJECT_VERSION}"#{$2}}
          end

          open(package, "w") { |file| file.write contents }
        end

        # Bump ember-metal/core version
        contents = File.read("packages/ember-metal/lib/core.js")
        current_version = contents.match(/Ember.VERSION = '([\w\.-]+)';$/) && $1
        contents.gsub!(current_version, PROJECT_VERSION);

        open("packages/ember-metal/lib/core.js", "w") do |file|
          file.write contents
        end
      end
    end

    desc "Commit framework version bump"
    task :commit do
      puts "Commiting Version Bump"
      unless pretend?
        sh("git reset")
        sh(%{git add VERSION CHANGELOG packages/ember-metal/lib/core.js ember.json packages/**/package.json})
        sh("git commit -m 'Version bump - #{PROJECT_VERSION}'")
      end
    end

    desc "Tag new version"
    task :tag do
      sh("git tag v#{PROJECT_VERSION}") unless pretend?
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
    task :prepare => [:update, :changelog, :bump_version]

    desc "Commit the new release"
    task :deploy => [:commit, :tag, :push]
  end
end
