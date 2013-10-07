require_relative '../../lib/ember-dev'

module EmberDev
  describe Config do

    describe "can convert project names to dasherized version" do
      it "handles Ember Data properly" do
        config = Config.new name: 'Ember Data'

        assert_equal 'ember-data', config.dasherized_name
      end

      it "handles Ember properly" do
        config = Config.new name: 'Ember'

        assert_equal 'ember', config.dasherized_name
      end
    end
  end
end
