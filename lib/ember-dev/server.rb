require 'rake-pipeline'
require 'rake-pipeline/middleware'
require 'erb'

module EmberDev
  class Server
    class HandlebarsJS
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/handlebars.js'
          [200, {'Content-Type' => 'text/javascript'}, [File.read(Handlebars::Source.bundled_path)]]
        else
          @app.call(env)
        end
      end
    end

    class EmberJS
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/ember.js'
          [200, {'Content-Type' => 'text/javascript'}, [File.read(::Ember::Source.bundled_path_for("ember.js"))]]
        else
          @app.call(env)
        end
      end
    end

    class EmberData
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/ember-data.js'
          [200, {'Content-Type' => 'text/javascript'}, [File.read(::Ember::Data::Source.bundled_path_for("ember-data.js"))]]
        else
          @app.call(env)
        end
      end
    end

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
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/'
          data = TestSiteGenerator.output

          [200, {'Content-Type' => 'text/html'}, [data]]
        else
          @app.call(env)
        end
      end
    end

    class ES6PackagesTranspile
      def initialize(app)
        @app = app
        @mtime = Float::MIN
      end

      def call(env)
        transpile if @mtime < compute_mtime

        @app.call(env)
      end

      def compute_mtime
        expanded_files.map { |f| File.mtime(f).to_f }.max || 0
      rescue Errno::ENOENT
        # if a file does no longer exist, the watcher is always stale.
        Float::MAX
      end

      def expanded_files
        Dir["packages_es6/**/*"]
      end

      def transpile
        executable_path = './bin/transpile-packages.js'

        if File.exist?(executable_path)
          `#{executable_path}`

          @mtime = compute_mtime
        end
      end
    end

    def initialize(project=nil)
      project ||= Rake::Pipeline::Project.new(EmberDev.config.assetfile)

      tests_root = File.expand_path("../../../support/tests", __FILE__)

      @app = Rack::Builder.app do
        use NoCache

        use ES6PackagesTranspile

        use Rake::Pipeline::Middleware, project

        # Include these after RakeP so we can serve from RakeP if available
        use HandlebarsJS
        use EmberJS
        use EmberData

        use ErbIndex
        run Rack::Directory.new(tests_root)
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end
