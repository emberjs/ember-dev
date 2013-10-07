require 'yaml'

module EmberDev
  class Config
    def self.from_file(path)
      options = File.exist?(path) ? YAML.load_file(path) : {}

      new(options)
    end

    attr_accessor :name
    attr_accessor :assetfile
    attr_accessor :testing_suites
    attr_accessor :testing_packages
    attr_accessor :testing_additional_requires
    attr_accessor :testing_needs_ember_data
    attr_accessor :testing_ember

    def initialize(hash)
      hash.each{|k,v| send("#{k}=", v) }

      @assetfile ||= EmberDev.support_path.join("Assetfile").to_s
      @testing_packages ||= []
    end

    def dasherized_name
      name.downcase.gsub(' ','-')
    end
  end
end
