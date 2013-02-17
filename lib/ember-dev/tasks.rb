require 'ember-dev'

EMBER_VERSION = File.read("VERSION").strip

Dir[File.expand_path("../../tasks/**/*.rake", __FILE__)].each{|f| load f }
