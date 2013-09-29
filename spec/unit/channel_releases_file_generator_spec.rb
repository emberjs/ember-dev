require 'minitest/autorun'

require_relative '../../lib/ember-dev'

module EmberDev
  describe ChannelReleasesFileGenerator do
    let(:git_support_mock) { Minitest::Mock.new }
    let(:generator) { ChannelReleasesFileGenerator.new(:git_support => git_support_mock, :project_name => 'Ember', :debug => false) }

    it "uses the provided project name" do
      generator = ChannelReleasesFileGenerator.new(:project_name => 'Ember Data', :debug => false)

      assert_equal 'Ember Data', generator.project_name
    end

    it "uses infers the project name from ember-dev.yml in the working directory" do
      Dir.chdir 'spec/support' do
        generator = ChannelReleasesFileGenerator.new :debug => false

        assert_equal 'Ember Dev', generator.project_name
      end
    end

    it "dasherizes the project name properly" do
      assert_equal 'ember-dev', generator.dasherized_project_name('Ember Dev')
      assert_equal 'ember-data', generator.dasherized_project_name('Ember Data')
      assert_equal 'ember', generator.dasherized_project_name('Ember')
    end

    it "uses the provided GitSupport to determine the current branch" do
      git_support_mock.expect :current_branch, 'blardy'

      assert_equal 'blardy', generator.current_branch
      git_support_mock.verify
    end

    it "uses the provided GitSupport to determine the current tag" do
      git_support_mock.expect :current_tag, 'v9999.99'

      assert_equal 'v9999.99', generator.current_tag
      git_support_mock.verify
    end

    it "knows the correct future version" do
      assert_equal '1.1.0', generator.future_version('v1.1.0-beta.1')
      assert_equal '1.0.0', generator.future_version('v1.0.0')
      assert_equal '1.0.1', generator.future_version('v1.0.1-rc.1')
    end

    it "knows the correct latest release" do
      assert_equal '1.1.0-beta.1', generator.last_release('v1.1.0-beta.1')
      assert_equal '1.0.0', generator.last_release('v1.0.0')
      assert_equal '1.0.1-rc.1', generator.last_release('v1.0.1-rc.1')
    end

    it "knows the correct channel" do
      assert_equal 'release', generator.channel('stable')
      assert_equal 'beta', generator.channel('beta')
      assert_equal 'canary', generator.channel('master')
    end

    describe "generates the correct content" do
      let(:generator) {ChannelReleasesFileGenerator.new(:git_support => git_support_mock, :project_name => 'Ember Data') }
      let(:expected_content_hash) do
        { 'projectName' => 'Ember Data',
          'projectFilter' => 'ember-data',
          'lastRelease' => '1.1.0-beta.1',
          'futureVersion' => '1.1.0',
          'channel'     => 'beta',
          'date'        => Date.today.to_s }
      end

      before do
        git_support_mock.expect :current_branch, 'beta'
        git_support_mock.expect :current_tag, 'v1.1.0-beta.1'
        git_support_mock.expect :current_tag, 'v1.1.0-beta.1'
      end

      it "for tagged betas" do
        assert_equal expected_content_hash, generator.content
      end

      it "produces valid JSON representing the content" do
        output = generator.to_json

        parsed_json = JSON.parse(output)

        assert_equal expected_content_hash, parsed_json
      end
    end

    it "knows where it should go in S3" do
      assert_equal '/release/ember-version.json', generator.destination_path('release', 'ember')
      assert_equal '/beta/ember-data-version.json', generator.destination_path('beta', 'ember-data')
      assert_equal '/canary/ember-version.json', generator.destination_path('canary', 'ember')
    end

    it "should return true to update? when a tag exists" do
      git_support_mock.expect :current_tag, 'v1.1.0-beta.1'

      assert_equal true, generator.should_generate?
    end

    it "should return true to update? when a tag exists" do
      git_support_mock.expect :current_tag, ''

      assert_equal false, generator.should_generate?
    end

  end
end
