require 'rake-pipeline'
require 'rake-pipeline/middleware'

module EmberDev
  class Server
    class NoCache
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env).tap do |status, headers, body|
          headers["Cache-Control"] = "no-store"
        end
      end
    end

    def initialize(project=nil)
      project ||= Rake::Pipeline::Project.new(File.expand_path("../assetfile.rb", __FILE__))

      tests_root = File.expand_path("../../../support/tests", __FILE__)

      @app = Rack::Builder.app do
        use NoCache
        use Rake::Pipeline::Middleware, project
        use Rack::Static , :index => "index.html", :root => tests_root
        run Rack::Directory.new(tests_root)
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end
