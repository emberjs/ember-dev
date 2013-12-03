namespace :ember do
  desc "Generate JSON for documentation with YUIDoc."
  task :docs do
    EmberDev::DocumentationGenerator.new.generate
  end
end
