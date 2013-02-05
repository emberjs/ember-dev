module EmberDev
  autoload :Config,  'ember-dev/config'
  autoload :Server,  'ember-dev/server'
  autoload :Version, 'ember-dev/version'

  def self.config
    @@config ||= Config.from_file('ember-dev.yml')
  end

  def self.support_path
    Pathname.new(File.expand_path("../../support", __FILE__))
  end
end
