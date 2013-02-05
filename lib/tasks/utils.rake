namespace :ember do
  desc "Strip trailing whitespace for JavaScript files in packages"
  task :strip_whitespace do
    Dir["packages/**/*.js"].each do |name|
      body = File.read(name)
      File.open(name, "w") do |file|
        file.write body.gsub(/ +\n/, "\n")
      end
    end
  end
end
