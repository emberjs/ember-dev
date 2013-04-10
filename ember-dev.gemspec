# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ember-dev/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Peter Wagenet", "Yehuda Katz"]
  gem.email         = ["peter.wagenet@gmail.com"]
  gem.description   = "Ember Package Development Tooling"
  gem.summary       = "Tooling for developing Ember packages."
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "ember-dev"
  gem.require_paths = ["lib"]
  gem.version       = EmberDev::VERSION

  gem.required_ruby_version = '>= 1.9.2'

  gem.add_dependency "rake-pipeline", "~> 0.8.0"
  gem.add_dependency "rake-pipeline-web-filters", "~> 0.7.0"
  gem.add_dependency "colored"
  gem.add_dependency "uglifier"
  gem.add_dependency "rack"
  gem.add_dependency "kicker"
  gem.add_dependency "grit"
  gem.add_dependency "execjs"
  gem.add_dependency "handlebars-source"
  gem.add_dependency "ember-source"
  gem.add_dependency "aws-sdk"
end

