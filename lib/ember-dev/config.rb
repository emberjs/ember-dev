require 'yaml'

module EmberDev
  class Config
    def self.from_file(path)
      new(YAML.load_file(path))
    end

    attr_accessor :name
    attr_accessor :assetfile
    attr_accessor :testing_suites
    attr_accessor :testing_packages
    attr_accessor :testing_additional_requires

    def initialize(hash)
      hash.each{|k,v| send("#{k}=", v) }

      @assetfile ||= EmberDev.support_path.join("Assetfile").to_s
      @testing_packages ||= []
    end
  end
end
