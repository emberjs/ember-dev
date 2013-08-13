require 'minitest/autorun'

require_relative '../lib/ember-dev/asset'

describe EmberDev::Publish::Asset do
  let(:described_class) { EmberDev::Publish::Asset }
  let(:asset_file)  { described_class.new('ember.js') }

  let(:filenames) { %w{ember.js ember-runtime.js ember.prod.js} }

  it "should accept a filename as input" do
    assert_raises(ArgumentError) { described_class.new }
  end

  it "knows about it's basename" do
    basenames = filenames.map { |f| described_class.new(f).basename.to_s }

    assert_equal %w{ember ember-runtime ember.prod}, basenames
  end

  it "returns a list of unminified_targets" do
    asset_file = described_class.new('some_dir/ember.js', 'BLAHBLAH')

    assert_equal %w{latest/ember.js BLAHBLAH/ember.js}, asset_file.unminified_targets
  end

  it "returns a list of minified_targets" do
    asset_file = described_class.new('ember.js', 'BLAHBLAH')

    assert_equal %w{latest/ember.min.js BLAHBLAH/ember.min.js}, asset_file.minified_targets
  end

  it "returns a list of production_targets" do
    asset_file = described_class.new('ember.js', 'BLAHBLAH')

    assert_equal %w{latest/ember.prod.js BLAHBLAH/ember.prod.js}, asset_file.production_targets
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

  it "returns a hash of source -> [S3 files]" do
    dir  = 'some_dir'
    base = 'blah'
    rev  = "GRRRRR"

    expected_hash = {
      Pathname.new("#{dir}/#{base}.js")      => ["latest/#{base}.js",      "#{rev}/#{base}.js"],
      Pathname.new("#{dir}/#{base}.min.js")  => ["latest/#{base}.min.js",  "#{rev}/#{base}.min.js"],
      Pathname.new("#{dir}/#{base}.prod.js") => ["latest/#{base}.prod.js", "#{rev}/#{base}.prod.js"],
    }
    asset_file = described_class.new("#{dir}/#{base}.js", rev)

    assert_equal expected_hash, asset_file.files_for_publishing
  end
end
