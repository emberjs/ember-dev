require 'pathname'
require 'fileutils'

module EmberDev
  class DocumentationGenerator
    def initialize(path = 'docs', generated_output_path = 'build/data.json', version_calculator = VersionCalculator.new)
      @version_calculator    = version_calculator
      @documentation_path    = Pathname.new(path)
      @generated_output_path = @documentation_path.join(generated_output_path)
    end

    def generate
      return true if @yuidoc_ran
      return false unless can_generate?

      run_yuidoc
    end

    def can_generate?
      yuidoc_available? && yuidoc_config_available?
    end

    def save_as(destination_path)
      return false unless generate

      FileUtils.cp(@generated_output_path.to_s, destination_path.to_s)
    end

    def version
      @version_calculator.version
    end

    private

    def yuidoc_config_available?
      @documentation_path.join('yuidoc.json').exist?
    end

    def yuidoc_available?
      system("yuidoc --version > /dev/null 2>&1")
    end

    def run_yuidoc
      @yuidoc_ran = system("cd #{@documentation_path} && yuidoc -p -q --project-version #{version}")
    end
  end
end
