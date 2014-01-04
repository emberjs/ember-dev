require 'fileutils'
require 'securerandom'
require 'minitest/autorun'

require_relative '../support/tmpdir_helpers'
require_relative '../../lib/ember-dev'

module EmberDev
  describe TestSiteGenerator do
    include TmpdirHelpers

    let(:random_string) { SecureRandom.base64(50) }
    let(:mock_template) { "<%= '#{random_string}' %>" }
    let(:support_test_dir) { Pathname.new(__FILE__).join('..', '..', '..','support','tests') }
    let(:real_template_path) { support_test_dir.join('index.html.erb') }

    let(:generator) { TestSiteGenerator.new(template: mock_template) }

    describe "#static_build?" do
      it "is true when option passed to initialize" do
        generator = TestSiteGenerator.new(template: mock_template, static: true)

        assert generator.static?, 'static? should be true'
      end

      it "is false when no option is passed to initialize" do
        generator = TestSiteGenerator.new(template: mock_template)

        refute generator.static?, 'static? should be false'
      end
    end

    describe 'template' do
      it "accepts a template" do
        generator = TestSiteGenerator.new(template: mock_template)

        assert_equal mock_template, generator.template
      end

      it "reads support/tests/index.html.erb if no template is specified" do
        Dir.chdir tmpdir do
          generator = TestSiteGenerator.new

          assert_equal File.read(real_template_path), generator.template
        end
      end
    end

    describe '#output' do
      it "uses template to generate output" do
        assert_equal random_string, generator.output
      end

      it "passes the current binding into the template" do
        mock_template = "Class: <%= self.class %>"
        generator = TestSiteGenerator.new(template: mock_template, static: true)

        assert_equal "Class: EmberDev::TestSiteGenerator", generator.output
      end
    end

    describe "#save" do
      it "creates a file at the specified path with the templates output" do
        generator.save(tmpdir + '/tests.html')

        assert_equal File.read(tmpdir + '/tests.html'), random_string
      end
    end

    it "returns the qunit_configuration" do
      expected_output = support_test_dir.join('qunit_configuration.js').read

      assert expected_output == generator.qunit_configuration_source
    end

    it "returns the minispade source" do
      expected_output = support_test_dir.join('minispade.js').read

      assert expected_output == generator.minispade_source
    end

    it "returns the jshint source" do
      expected_output = support_test_dir.join('jshint.js').read

      assert expected_output == generator.jshint_source
    end

    it "returns the features portion of features.json" do
      expected_output = '{"blah-feature":true}'

      Dir.chdir 'spec/support' do
        assert_equal generator.features, expected_output
      end
    end
  end
end
