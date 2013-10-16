require 'pathname'

module EmberDev
  autoload :Config,      'ember-dev/config'
  autoload :Server,      'ember-dev/server'
  autoload :Version,     'ember-dev/version'
  autoload :Publish,     'ember-dev/publish'
  autoload :TestSupport, 'ember-dev/test_support'
  autoload :TestRunner,  'ember-dev/test_runner'
  autoload :GitSupport,  'ember-dev/git_support'

  autoload :VersionCalculator,            'ember-dev/version_calculator'
  autoload :TestSiteGenerator,            'ember-dev/test_site_generator'
  autoload :DocumentationGenerator,       'ember-dev/documentation_generator'
  autoload :ChannelReleasesFileGenerator, 'ember-dev/channel_releases_file_generator'

  def self.config
    @@config ||= Config.from_file('ember-dev.yml')
  end

  def self.support_path
    Pathname.new(File.expand_path("../../support", __FILE__))
  end
end
