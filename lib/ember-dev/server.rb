require 'rake-pipeline'
require 'rake-pipeline/middleware'
require 'erb'

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

    class ErbIndex
      def initialize(app, root)
        @app = app
        @root = root
      end

      def call(env)
        if env['PATH_INFO'] == '/'
          data = ERB.new(File.read(File.join(@root, 'index.html.erb'))).result
          [200, {'Content-Type' => 'text/html'}, [data]]
        else
          @app.call(env)
        end
      end
    end

    def initialize(project=nil)
      project ||= Rake::Pipeline::Project.new(EmberDev.config.assetfile)

      tests_root = File.expand_path("../../../support/tests", __FILE__)

      @app = Rack::Builder.app do
        use NoCache
        use Rake::Pipeline::Middleware, project
        use ErbIndex, tests_root
        run Rack::Directory.new(tests_root)
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end
