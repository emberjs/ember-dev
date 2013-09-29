require 'erb'
require 'fileutils'

module EmberDev
  class TestSiteGenerator
    attr_reader :template

    def self.output(template = nil)
      new(template: template).output
    end

    def initialize(options = nil)
      options ||= {}

      @static   = options.fetch(:static, false)
      @template = options.fetch(:template, nil)
    end

    def template
      @template ||= File.read(default_template_path)
    end

    def output
      ERB.new(template).result(binding)
    end

    def save(path)
      path = Pathname.new(path)
      path.dirname.mkpath

      path.open('w') { |io| io.write output }
    end

    def static?
      @static
    end

    def qunit_configuration_source
      asset_root_path.join('qunit_configuration.js').read
    end

    def minispade_source
      asset_root_path.join('minispade.js').read
    end

    def jshint_source
      asset_root_path.join('jshint.js').read
    end

    private

    def asset_root_path
      Pathname.new(__FILE__).join(*%w{.. .. .. support tests})
    end

    def default_template_path
      asset_root_path.join('index.html.erb')
    end
  end
end
