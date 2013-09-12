require 'minitest/autorun'

require_relative '../../lib/ember-dev/asset'

describe EmberDev::Publish::Asset do
  let(:described_class) { EmberDev::Publish::Asset }
  let(:asset_file)  { described_class.new('ember.js') }
  let(:todays_date) { Date.today.strftime("%Y%m%d") }

  let(:filenames) { %w{ember.js ember-runtime.js ember.prod.js} }

  before do
    asset_file.ignore_missing_files = true
  end

  it "should accept a filename as input" do
    assert_raises(ArgumentError) { described_class.new }
  end

  it "knows about it's basename" do
    basenames = filenames.map { |f| described_class.new(f).basename.to_s }

    assert_equal %w{ember ember-runtime ember.prod}, basenames
  end

  describe "#targets_for" do
    let(:base_targets) {
      %W{ ember-latest.js
          latest/ember.js
          canary/ember.js
          canary/daily/#{todays_date}/ember.js
          canary/shas/BLAHBLAH/ember.js} }

    it "doesn't return the tagged_path if no tag is present" do
      asset_file = described_class.new('some_dir/ember.js', revision: 'BLAHBLAH', tag: '')

      assert_equal base_targets, asset_file.targets_for('.js')
    end

    it "includes a tagged path if a tag is present" do
      asset_file = described_class.new('some_dir/ember.js', revision: 'BLAHBLAH', tag: 'v999')

      assert_equal base_targets + ['tags/v999/ember.js'], asset_file.targets_for('.js')
    end

    it "includes stable path if a stable => true" do
      stable_targets = %W{ stable/ember.js
                           release/ember.js
                           release/daily/#{todays_date}/ember.js
                           release/shas/BLAHBLAH/ember.js
                           tags/v999/ember.js}

      asset_file = described_class.new('some_dir/ember.js', revision: 'BLAHBLAH', tag: 'v999', build_type: :release)

      assert_equal stable_targets, asset_file.targets_for('.js')
    end

    it "doesn't return anything if tags_only is set and no tag is present" do
      asset_file = described_class.new('some_dir/ember.js', revision: 'BLAHBLAH', tags_only: true)

      assert_equal [], asset_file.targets_for('.js')
    end

    it "returns only the tags/ item when tags_only is set with a tag present" do
      asset_file = described_class.new('some_dir/ember.js', revision: 'BLAHBLAH', tag: 'v999', tags_only: true)

      assert_equal ['tags/v999/ember.js'], asset_file.targets_for('.js')
    end
  end

  it "returns a list of unminified_targets" do
    asset_file = described_class.new('some_dir/ember.js', revision: 'BLAHBLAH')
    expected_targets = %W{ ember-latest.js
                           latest/ember.js
                           canary/ember.js
                           canary/daily/#{todays_date}/ember.js
                           canary/shas/BLAHBLAH/ember.js }

    assert_equal expected_targets, asset_file.unminified_targets
  end

  it "uses the initial file extension as the base for all targets" do
    asset_file = described_class.new('some_dir/ember.grrr', revision: 'BLAHBLAH')
    expected_targets = %W{ ember-latest.grrr
                           latest/ember.grrr
                           canary/ember.grrr
                           canary/daily/#{todays_date}/ember.grrr
                           canary/shas/BLAHBLAH/ember.grrr }

    assert_equal expected_targets, asset_file.unminified_targets
  end

  it "returns a list of minified_targets" do
    expected_targets = %W{ ember-latest.min.js
                           latest/ember.min.js
                           canary/ember.min.js
                           canary/daily/#{todays_date}/ember.min.js
                           canary/shas/BLAHBLAH/ember.min.js}

    asset_file = described_class.new('ember.js', revision: 'BLAHBLAH')

    assert_equal expected_targets, asset_file.minified_targets
  end

  it "returns a list of production_targets" do
    expected_targets = %W{ember-latest.prod.js
                          latest/ember.prod.js
                          canary/ember.prod.js
                          canary/daily/#{todays_date}/ember.prod.js
                          canary/shas/BLAHBLAH/ember.prod.js}

    asset_file = described_class.new('ember.js', revision: 'BLAHBLAH')

    assert_equal expected_targets, asset_file.production_targets
  end

  it "knows the location of it's minified source" do
    asset_file = described_class.new('some_dir/ember.js')

    assert_equal 'some_dir/ember.min.js', asset_file.minified_source.to_s
  end

  it "returns the passed in filename for unminified_source" do
    path = Pathname.new 'blah/blah/blah/blah.js'

    asset_file = described_class.new(path.to_s)

    assert_equal path, asset_file.unminified_source
  end

  it "knows the location of it's production version" do
    asset_file = described_class.new('some_dir/blah.js')

    assert_equal 'some_dir/blah.prod.js', asset_file.production_source.to_s
  end

  describe "returns a hash of source -> [S3 files]" do
    let(:dir)  { 'some_dir' }
    let(:rev)  { 'ARGGG' }
    let(:tag)  { '' }
    let(:base) { 'blah' }

    let(:expected_hash) do
      {
        asset_file.unminified_source => asset_file.targets_for(".js"),
        asset_file.minified_source   => asset_file.targets_for(".min.js"),
        asset_file.production_source => asset_file.targets_for(".prod.js"),
      }
    end

    describe "for a tagged release" do
      let(:tag) { 'v999' }

      it "includes a tagged release if tag is present" do
        assert_equal expected_hash, asset_file.files_for_publishing
      end
    end

    describe "for a non-tagged revision" do
      let(:tag) { '' }

      it "doesn't include a tagged release if tag is empty/nil" do
        assert_equal expected_hash, asset_file.files_for_publishing
      end
    end

    describe "only outputs files that exist in files_for_publishing" do
      before do
        asset_file.ignore_missing_files = false
      end

      it "doesn't include anything if no files exist" do
        assert_equal({}, asset_file.files_for_publishing)
      end
    end
  end
end
