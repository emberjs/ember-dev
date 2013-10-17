require "rake-pipeline-web-filters"
require "json"
require "execjs"
require "handlebars/source"

class EmberStripDebugMessagesFilter < Rake::Pipeline::Filter
  def strip_debug(data)
    # Strip debug code
    data.gsub!(%r{^(\s)*Ember\.(assert|deprecate|warn|debug)\((.*)\).*$}, "")
  end

  def add_localhost_warning(data)
    data << "\n\n" + <<END
if (typeof location !== 'undefined' && (location.hostname === 'localhost' || location.hostname === '127.0.0.1')) {
  Ember.Logger.warn("You are running a production build of Ember on localhost and won't receive detailed error messages. "+
               "If you want full error messages please use the non-minified build provided on the Ember website.");
}
END
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      result = File.read(input.fullpath)
      strip_debug(result)
      add_localhost_warning(result)
      output.write result
    end
  end
end

class HandlebarsPrecompiler < Rake::Pipeline::Filter
  class << self
    def context
      unless @context
        contents = <<END
exports = {};

// This is necessary to browserify the ember-template-compiler node module,
// which needs to `require('handlebars')`. A more complex solution may 
// be desirable in the future if ember-template-compiler needs to require more modules.
function require() {
  #{File.read(Handlebars::Source.bundled_path)};
  return Handlebars;
}

#{File.read("dist/ember-template-compiler.js")}
function precompileEmberHandlebars(string) {
  return exports.precompile(string).toString();
}
END
        @context = ExecJS.compile(contents)
      end
      @context
    end
  end

  def precompile_templates(data)
    # Precompile defaultTemplates
   data.gsub!(%r{(defaultTemplate(?:\s*=|:)\s*)precompileTemplate\(['"](.*)['"]\)}) do
     "#{$1}Ember.Handlebars.template(#{self.class.context.call("precompileEmberHandlebars", $2)})"
   end
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      result = File.read(input.fullpath)
      precompile_templates(result)
      output.write result
    end
  end
end

class EmberLicenseFilter < Rake::Pipeline::Filter
  def license
    @license ||= File.read("generators/license.js")
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      file = File.read(input.fullpath)
      output.write "#{license}\n\n#{file}"
    end
  end
end

class JSHintRC < Rake::Pipeline::Filter
  JSHINTRC = File.expand_path(".jshintrc")

  def jshintrc
    @jshintrc ||= File.read(JSHINTRC)
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      file = File.read(input.fullpath)
      output.write "var JSHINTRC = #{jshintrc};\n\n#{file}"
    end
  end

  def additional_dependencies(input)
    [ JSHINTRC ]
  end
end

class AddProjectVersionNumber < Rake::Pipeline::Filter
  def version
    @version ||= EmberDev::VersionCalculator.new.version
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      # Bump ember-metal/core version
      contents = File.read(input.fullpath)
      contents.gsub!(/VERSION_STRING_PLACEHOLDER/, version)
      output.write contents
    end
  end
end

class VersionInfo < Rake::Pipeline::Filter
  def version
    @version ||= EmberDev::VersionCalculator.new.version
  end

  def version_info
    @version_info ||= " // Version: #{version}"
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      file = File.read(input.fullpath)
      output.write "#{version_info}\n\n#{file}"
    end
  end
end

class EmberStub < Rake::Pipeline::Filter
  def generate_output(inputs, output)
    inputs.each do |input|
      file = File.read(input.fullpath)
      out = "(function() {\nvar Ember = { assert: function() {}, FEATURES: { isEnabled: function() {} } };\n"

      out << file
      out << "\nexports.precompile = Ember.Handlebars.precompile;"
      out << "\nexports.EmberHandlebars = Ember.Handlebars;"
      out << "\n})();"
      output.write out
    end
  end
end

class EmberAddMicroLoader < Rake::Pipeline::Filter
  LOADER = File.expand_path("../../../../support/assets/loader.js", __FILE__)

  def initialize(options={}, &block)
    super(&block)
    @global = options[:global]
  end

  def generate_output(inputs, output)
    output.write "(function() {\n" unless @global

    output.write File.read(LOADER)

    inputs.each do |input|
      output.write input.read
    end

    output.write "\n})();\n" unless @global
  end

  def additional_dependencies(input)
    [ LOADER ]
  end
end

class EmberDefeatureify < Rake::Pipeline::Filter
  def generate_output(inputs, output)
    inputs.each do |input|
      src = `defeatureify #{input.fullpath} -w features.json`
      output.write src
    end
  end
end
