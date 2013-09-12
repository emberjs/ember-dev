namespace :ember do
  desc "Generate documentation with YUIDoc."
  task :docs do
    EmberDev::DocumentationGenerator.new.generate
  end
end
