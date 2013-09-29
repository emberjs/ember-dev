require 'json'
require_relative 'publish'
require_relative 'git_support'

module EmberDev
  class ChannelReleasesFileGenerator
    attr_reader :git_support, :project_name
    private :git_support

    def initialize(options = nil)
      options ||= {}

      @debug = options.fetch(:debug, true)
      @git_support = options.fetch(:git_support) { GitSupport.new '.', :debug => @debug }
      @project_name = options.fetch(:project_name) { EmberDev::Config.from_file('ember-dev.yml').name }
    end

    def dasherized_project_name(name = project_name)
      name.gsub(/\W/, '-').downcase
    end

    def current_branch
      git_support.current_branch
    end

    def current_tag
      git_support.current_tag
    end

    def last_release(tag = current_tag)
      tag =~ /v(.+)/; $1
    end

    def future_version(tag = current_tag)
      tag =~ /v([0-9.]+)(?:-.+)?/; $1
    end

    def channel(branch = current_branch)
      case branch
      when 'stable','release' then 'release'
      when 'beta'             then 'beta'
      when 'master'           then 'canary'
      end
    end

    def content
      { 'projectName'   => project_name,
        'projectFilter' => dasherized_project_name,
        'lastRelease'   => last_release,
        'futureVersion' => future_version,
        'channel'       => channel,
        'date'          => Date.today.to_s }
    end

    def to_json
      content.to_json
    end

    def destination_path(channel = channel, dasherized_project_name = dasherized_project_name)
      "/#{channel}/#{dasherized_project_name}-version.json"
    end

    def should_generate?
      current_tag.to_s.strip.length > 0
    end
  end
end
