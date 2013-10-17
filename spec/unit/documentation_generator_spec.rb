require 'tmpdir'
require 'fileutils'
require 'minitest/autorun'

require_relative '../support/tmpdir_helpers'
require_relative '../../lib/ember-dev/documentation_generator'

module EmberDev
  describe DocumentationGenerator do
    include TmpdirHelpers

    let(:docs_root) { tmpdir + '/docs' }
    let(:yuidoc_config_file) { docs_root + '/yuidoc.json' }
    let(:generator) { DocumentationGenerator.new(docs_root, 'build/data.json', mock_version_calc) }
    let(:mock_version_calc) { Minitest::Mock.new }
    let(:random_version) { SecureRandom.urlsafe_base64 }

    def touch(path)
      FileUtils.mkdir_p File.dirname(path)
      File.open(path, 'w+'){|io| io.write ''}
    end

    def setup_yuidoc_config
      touch(yuidoc_config_file)
    end

    def fake_run_yuidoc
      def generator.run_yuidoc; @yuidoc_ran = true; end;
      def generator.yuidoc_ran?; @yuidoc_ran; end;
    end

    before do
      setup_yuidoc_config
      mock_version_calc.expect :version, random_version
    end

    it "can accept the documentation directory on initialize" do
      DocumentationGenerator.new(docs_root)
    end

    it "uses VersionCalculator to find the current version number" do
      mock_calculator = Minitest::Mock.new
      mock_calculator.expect :version, 'BLAHZORZ'

      VersionCalculator.stub :new, mock_calculator do
        generator = DocumentationGenerator.new(docs_root)

        assert_equal 'BLAHZORZ', generator.version
      end
    end

    describe "knows when it can't generate documentation" do
      it "will not attempt to generate docs if yuidoc isn't available" do
        def generator.yuidoc_available?; false; end

        refute generator.can_generate?, 'generate should return false if `yuidoc` is unavailable'
      end

      it "will not attempt to generate docs if no yuidoc config is available" do
        FileUtils.rm yuidoc_config_file

        refute generator.can_generate?, 'generate should return false if `yuidoc.json` is not present'
      end

      it "will generate if both yuidoc and it's configs are available" do
        def generator.yuidoc_available?; true; end
        def generator.yuidoc_config_available?; true; end

        assert generator.can_generate?
      end
    end

    describe "allows you to save off the output to a specific file" do
      let(:initial_output_path) { docs_root + '/build/data.json' }
      let(:desired_output_path) { tmpdir + '/somefile.json' }

      before do
        fake_run_yuidoc
        touch(initial_output_path)
      end

      it "calls generate if not already called" do
        refute generator.yuidoc_ran?

        generator.save_as(desired_output_path)

        assert generator.yuidoc_ran?
      end

      it "copies the ouput to the desired location" do
        generator.save_as(desired_output_path)

        assert File.exists?(desired_output_path)
      end
    end

    it "runs yuidoc on generate" do
      fake_run_yuidoc

      def generator.can_generate?; true; end;

      generator.generate

      assert generator.yuidoc_ran?
    end
  end
end
