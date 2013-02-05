def setup_uploads
  unless File.exist?('tmp/dist')
    remotes = `git remote -v`
    remotes = remotes.split("\n").map do |r|
      m = r.match(/(?<name>.+)\t(?<url>.+) \((?<type>.+)\)$/)
      Hash[*m.names.map{|n| [n, m[n]]}.flatten]
    end

    remote = remotes.find{|r| r['name'] == 'origin' && r['type'] == 'push' }

    unless remote
      raise "Couldn't find url for pushing to origin"
    end

    mkdir_p 'tmp'

    # TODO: See if we can only fetch the branches we need
    system("git clone #{remote['url']} tmp/dist")
  end
end

namespace :ember do
  desc "Upload latest Ember.js build to GitHub repository"
  task :upload_latest => [:clean, :dist] do
    setup_uploads

    Dir.chdir "tmp/dist" do
      system("git checkout latest-builds")
      cp "../../dist/ember.js", ".", :verbose => false
      cp "../../dist/ember.min.js", ".", :verbose => false
      system("git add ember.js ember.min.js")
      system('git commit --amend --reset-author -m "Latest Builds"')
      system("git push -f origin latest-builds") unless ENV['PRETEND']
    end
  end
end
