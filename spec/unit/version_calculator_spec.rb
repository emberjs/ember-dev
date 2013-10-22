require 'minitest/autorun'

require_relative '../../lib/ember-dev/version_calculator'

module EmberDev
  describe VersionCalculator do
    include TmpdirHelpers

    let(:calc) { VersionCalculator.new options}
    let(:options) do
      {version_file_contents: fake_file_contents,
       git_support: mock_git_support,
       debug: false}
    end

    let(:mock_git_support) { Minitest::Mock.new }
    let(:fake_file_contents) { 'Some Random String' }

    describe "#version_file_contents" do
      it "looks up from a version file in the current directory." do
        expected_version_number = SecureRandom.urlsafe_base64

        calc = VersionCalculator.new
        Dir.chdir tmpdir do
          File.write('VERSION', expected_version_number)

          assert_equal expected_version_number, calc.version_file_contents
        end
      end

      it "looks up from a version file in the current directory." do
        expected_version_number = SecureRandom.urlsafe_base64

        calc = VersionCalculator.new
        Dir.chdir tmpdir do
          File.write('VERSION', expected_version_number + "\n\n" + expected_version_number)

          assert_equal expected_version_number * 2, calc.version_file_contents
        end
      end

      it "can be supplied on initialization" do
        calc = VersionCalculator.new version_file_contents: fake_file_contents

        assert_equal fake_file_contents, calc.version_file_contents
      end
    end

    describe "#contains_metadata_tag?" do
      it "returns true if `+` is present in version_file_contents" do
        calc = VersionCalculator.new version_file_contents: 'something+else'

        assert calc.contains_metadata_tag?
      end

      it "returns false if `+` is not present in version_file_contents" do
        calc = VersionCalculator.new version_file_contents: 'something else'

        refute calc.contains_metadata_tag?
      end
    end

    describe "#short_revision" do
      it "should return the first 8 characters of the revision" do
        def calc.revision; '12345678901234567890'; end

        assert_equal '12345678', calc.short_revision
      end
    end

    describe "#revision" do
      let(:random_revision)  { SecureRandom.urlsafe_base64 }

      it "uses GitSupport to get the current revision" do
        mock_git_support.expect :current_revision, random_revision

        assert_equal random_revision, calc.revision

        mock_git_support.verify
      end
    end

    describe "#version" do
      before do
        def calc.revision; @revision_called = true; '123456789012345678901234567890'; end
        def calc.revision_called; @revision_called; end

        def calc.contains_metadata_tag_called; @contains_metadata_tag_called; end
      end

      describe "with a `+` in the version_file_contents" do
        let(:fake_file_contents) { 'blahblah+canary' }

        before do
          def calc.contains_metadata_tag?; @contains_metadata_tag_called = true; true end
        end

        it "should return the version_file_contents with the short revision appended" do
          assert_equal fake_file_contents + ".12345678", calc.version
        end

        it "should call revision" do
          calc.version

          assert calc.revision_called
        end
      end

      describe "without a `+` in the version_file_contents" do
        let(:fake_file_contents) { 'blahblah' }

        before do
          def calc.contains_metadata_tag?; @contains_metadata_tag_called = true; false end
        end

        it "should return the raw version_file_contents" do
          assert_equal fake_file_contents, calc.version
        end

        it "should not call revision" do
          calc.version

          refute calc.revision_called
        end
      end
    end
  end
end

__END__

The idea here is that we keep the next tagged version number with either `+pre` or `+canary` in the repo under `/VERSION`. Then before tagging/releasing a new version we update the `VERSION` file to remove the `+<SUFFIX>`.

If the `+` isn't present we simply use the value of `VERSION`.

It will take the VERSION file value and append `+pre.<SHA>` (where <SHA> is the current SHA).

Examples:

VERSION Contents    | SHA     | Branch | Resulting Version Value
--------------------+---------+--------+-------------------------
1.1.0-beta.4+pre    | dsfaf12 | beta   | 1.1.0-beta.4+pre.dsfaf12
1.2.0-beta.1+canary | lkmasdf | master | 1.2.0-beta.1+canary.lkmasdf
1.1.0               | amnj123 | ANY    | 1.1.0
1.2.0-beta.1        | iyqwe89 | beta   | 1.2.0-beta.1

