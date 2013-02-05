Encoding.default_external = "UTF-8" if defined?(Encoding)

require "ember-dev/rakep/filters"

distros = {
  "runtime"           => %w(ember-metal rsvp container ember-runtime),
  "template-compiler" => %w(handlebars ember-handlebars-compiler),
  "data-deps"         => %w(ember-metal rsvp container ember-runtime ember-states),
  "full"              => %w(ember-metal rsvp container ember-runtime ember-views metamorph ember-handlebars-compiler ember-handlebars ember-routing ember-application ember-states),
  "old-router"        => %w(ember-metal rsvp container ember-runtime ember-views ember-states ember-viewstates metamorph ember-handlebars-compiler ember-handlebars ember-old-router )
}

output "dist"

input "packages" do
  match "*/tests/**/*.js" do
    minispade :rewrite_requires => true, :string => true, :module_id_generator => proc { |input|
      id = input.path.dup
      id.sub!(/\.js$/, '')
      id.sub!(/\/main$/, '')
      id.sub!('/tests', '/~tests')
      id
    }

    concat "ember-tests.js"
  end

  match "ember-tests.js" do
    filter JSHintRC
  end
end

input "packages" do
  match "*/lib/**/*.js" do
    minispade :rewrite_requires => true, :string => true, :module_id_generator => proc { |input|
      id = input.path.dup
      id.sub!('/lib/', '/')
      id.sub!(/\.js$/, '')
      id.sub!(/\/main$/, '')
      id
    }

    concat "ember-spade.js"
    filter AddMicroLoader, :global => true
  end
end

input "packages" do
  match "*/lib/**/main.js" do
    neuter(
      :additional_dependencies => proc { |input|
        Dir.glob(File.join(File.dirname(input.fullpath),'**','*.js'))
      },
      :path_transform => proc { |path, input|
        package, path = path.split('/', 2)
        current_package = input.path.split('/', 2)[0]
        current_package == package && path ? File.join(package, "lib", "#{path}.js") : nil
      },
      :closure_wrap => true
    ) do |filename|
      File.join("modules/", filename.gsub('/lib/main.js', '.js'))
    end
  end
end

distros.each do |name, modules|
  name = name == "full" ? "ember" : "ember-#{name}"

  input "dist/modules" do
    module_paths = modules.map{|m| "#{m}.js" }
    match "{#{module_paths.join(',')}}" do
      concat(module_paths){ ["#{name}.js", "#{name}.prod.js"] }
      filter HandlebarsPrecompiler
      filter AddMicroLoader unless name == "ember-template-compiler"
    end

    # Add debug to the main distro
    match "{#{name}.js,ember-debug.js}" do
      filter VersionInfo
      concat ["ember-debug.js"], "#{name}.js" unless name == "ember-template-compiler"
      filter EmberStub if name == "ember-template-compiler"
    end

    # Strip dev code
    match "#{name}.prod.js" do
      filter(EmberStripDebugMessagesFilter) { ["#{name}.prod.js", "min/#{name}.js"] }
    end

    # Minify
    match "min/#{name}.js" do
      uglify{ "#{name}.min.js" }
      filter VersionInfo
      filter EmberLicenseFilter
    end
  end
end

# vim: filetype=ruby
