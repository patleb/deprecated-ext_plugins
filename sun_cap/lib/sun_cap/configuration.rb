module SunCap
  @@config = nil

  def self.configure
    @@config ||= Configuration.new

    if block_given?
      yield config
    end

    config
  end

  def self.config
    @@config || configure
  end

  class Configuration
    attr_writer :capistrano

    def initialize
      sunzistrano.each do |name, value|
        self.class.send :define_method, name do
          value
        end
      end
    end

    def capistrano
      @capistrano ||= %i(
        admin_name
        application
        app_root
        deploy_dir
        deploy_to
        nginx_domain
        rbenv_ruby
        server
        stage
      )
    end

    def sunzistrano
      @sunzistrano ||= {
        DEPLOY_LOG: 'sun_deploy.log',
        DEPLOY_DIR: 'sun_deploy',
        MANIFEST_LOG: 'sun_manifest.log',
        MANIFEST_DIR: 'sun_manifest',
        DEFAULTS_DIR: 'sun_defaults',
      }
    end
  end
end
