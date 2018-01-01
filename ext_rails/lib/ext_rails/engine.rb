require "ext_rails/configuration"

module ActiveHelper
  autoload :Base, "ext_rails/active_helper/base"
end

module ExtRails
  class Engine < Rails::Engine
    if Rails::VERSION::STRING < '5.2'
      require 'active_record_query_trace' if Rails.env.development?
      require 'ext_rails/active_support/current_attributes_rails_5_1'
    end
    require 'active_type'
    require 'activerecord-rescue_from_duplicate'
    require 'activevalidators'
    require 'baby_squeel' # https://github.com/activerecord-hackery/polyamorous/issues/26
    require 'bumbler' if Rails.env.development?
    require 'countries'
    require 'email_prefixer'
    require 'ext_mail'
    require 'ext_ruby'
    require 'hamlit-rails'
    require 'http_accept_language'
    require 'i18n/debug' if Rails.env.development?
    require 'jsonb_accessor'
    require 'logidze'
    require 'mail_interceptor' unless Rails.env.production?
    require 'ext_rails/money_rails'
    # TODO https://github.com/procore/migration-lock-timeout
    require 'monogamy'
    require 'nestive'
    require 'null_logger' if Rails.env.development?
    # TODO update to version 3
    require 'oj'
    require 'oj/active_support_helper'
    require 'pg'
    require 'query_diet' if Rails.env.development?
    require 'rails-i18n'
    require 'settings_yml'
    require 'time_difference'
    require 'ext_rails/countries/country'
    require 'ext_rails/action_mailer/smtp_settings'
    require 'ext_rails/active_support/core_ext'
    require 'ext_rails/active_support/current_attributes'

    config.before_configuration do |app|
      Rails.application.send :define_singleton_method, :name do
        @_name ||= Rails.application.engine_name.sub(/_application$/, '')
      end

      Rails.application.send :define_singleton_method, :title do
        @_title ||= Rails.application.name.titleize
      end

      Rails.application.send :define_singleton_method, :remote_ip do
        @_remote_ip ||= case Rails.env.to_sym
          when :vagrant
            `ip addr show eth1 | awk '/inet / {print $2}' | cut -d/ -f1`.strip
          when :development, :test
            '127.0.0.1'
          else
            open('http://whatismyip.akamai.com').read
        end
      end

      Rails.application.send :define_singleton_method, :web_workers do
        @_web_workers_dir ||= Dir.pwd.sub /\/releases\/\d{14}/, '/current/public'
        `pgrep -lf 'Passenger RubyApp: #{@_web_workers_dir}' | grep ruby | cut -d' ' -f1`.split("\n")
      end

      # app.config.i18n.fallbacks = true
      # app.config.i18n.fallbacks = [:en]
      app.config.action_mailer.delivery_method = :smtp
      app.config.action_mailer.smtp_settings = ActionMailer::SmtpSettings.new(SettingsYml)
      app.config.action_view.embed_authenticity_token_in_remote_forms = true
      app.config.active_record.schema_format = :sql
      app.config.i18n.default_locale = :fr
      app.config.i18n.available_locales = [:fr, :en]

      if Rails.env.development?
        localhost = ENV['NGROK'] ? "#{ENV['NGROK']}.ngrok.io" : 'localhost:3000'
        app.config.action_controller.asset_host = "http://#{localhost}"
        app.config.action_mailer.asset_host = app.config.action_controller.asset_host
        app.config.action_mailer.default_url_options = { host: localhost }
      end

      if Rails.env.development? || Rails.env.test?
        app.config.logger = ActiveSupport::Logger.new(app.config.paths['log'].first, 5)
        app.config.logger.formatter = app.config.log_formatter
      else
        app.config.action_mailer.default_url_options = -> { { host: SettingsYml[:server] } }
      end
    end

    config.before_initialize do |app|
      module ::ActiveModel
        module Validations
          ActiveValidators.activevalidators.each do |type|
            autoload :"#{type.camelize}Validator", "ext_rails/active_record/validations"
          end
        end
      end

      if Rails.env.development?
        require "ext_rails/action_dispatch/turbo_dev"

        app.config.middleware.insert 0, ActionDispatch::TurboDev
      end

      if Rails.env.development? || Rails.env.test?
        Rails::Initializable::Initializer.class_eval do
          def self.skipped_initializers
            @skipped_initializers ||= Set.new(%w(
              sendgrid_actionmailer.add_delivery_method
              email_prefixer.configure_defaults
            ))
          end
          delegate :skipped_initializers, to: :class

          module SkippedInitializers
            def run(*args)
              super unless skipped_initializers.include?(name)
            end
          end
          prepend SkippedInitializers
        end
      end
    end

    if Rails::VERSION::STRING < '5.2'
      initializer "ext_rails.current_attributes", before: "active_support.deprecation_behavior" do |app|
        app.reloader.before_class_unload { ActiveSupport::CurrentAttributes.clear_all }
        app.executor.to_run              { ActiveSupport::CurrentAttributes.reset_all }
        app.executor.to_complete         { ActiveSupport::CurrentAttributes.reset_all }
      end
    end

    initializer 'ext_rails.default_url_options', before: 'action_mailer.set_configs' do |app|
      default_url_options = app.config.action_mailer.default_url_options
      if default_url_options.respond_to? :call
        app.config.action_mailer.default_url_options = default_url_options.call
      end
      app.routes.default_url_options = app.config.action_mailer.default_url_options
    end

    initializer "ext_rails.active_record_query_trace" do
      if defined? ::ActiveRecordQueryTrace
        ActiveRecordQueryTrace.enabled = ExtRails.config.query_debug
        ActiveRecordQueryTrace.level = :full
        ActiveRecordQueryTrace.lines = 40
      end
    end

    initializer 'ext_rails.i18n_debug' do
      if defined? ::I18n::Debug
        unless ExtRails.config.i18n_debug
          I18n::Debug.logger = NullLogger.new
        end
      end
    end

    initializer 'ext_rails.append_migrations' do |app|
      unless ExtRails.config.skip_migrations
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end

    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.class_eval do
        helper ExtRails::Engine.helpers
        include ExtRails::ViewHelper
        include ExtRails::WithActiveHelper
        include ExtRails::WithContext
        include ExtRails::WithLogger
        include ExtRails::WithDispatch
      end

      ActionController::API.class_eval do
        include ActionController::MimeResponds
        include ExtRails::WithLogger
        include ExtRails::WithDispatch
      end
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'ext_rails/action_mailer/with_attachment_fix'
      require 'ext_rails/action_mailer/with_quiet_info'

      ActionMailer::Base.class_eval do
        prepend ActionMailer::WithAttachmentFix
      end

      ActionMailer::LogSubscriber.class_eval do
        prepend ActionMailer::WithQuietInfo
      end

      if defined?(MailInterceptor)
        options = {
          forward_emails_to: Class.new do
            def self.to_ary
              Class.new do
                def self.flatten
                  Class.new do
                    def self.uniq
                      (defined?(Setting) ? Setting : SettingsYml)[:mail_to]
                    end
                  end
                end
              end
            end
          end
        }
        interceptor = MailInterceptor::Interceptor.new(options)

        ActionMailer::Base.register_interceptor(interceptor)
      end
    end

    ActiveSupport.on_load(:action_view) do
      require 'ext_rails/action_view/with_template_virtual_path'

      ActionView::TemplateRenderer.class_eval do
        prepend ActionView::WithTemplateVirtualPath
      end
    end

    ActiveSupport.on_load(:active_record) do
      require "ext_rails/active_record/connection_adapters/postgresql_adapter"
      require "ext_rails/active_type"
      require "ext_rails/active_support/json/encoding/oj"
      require "ext_rails/active_record/base"
      require "ext_rails/active_record/relation"
    end

    config.to_prepare do
      require 'ext_rails/action_dispatch/with_only_path'

      ActionDispatch::Routing::UrlFor.module_eval do
        prepend ActionDispatch::WithOnlyPath
      end

      (Rails::Engine.subclasses.map(&:root) << Rails.root).each do |root|
        Dir[root.join('app', 'controllers', '**', '*_controller.rb')].each do |name|
          controller = name.match(/app\/controllers\/(.+)\.rb/)[1].camelize.safe_constantize
          if controller&.superclass.in? [ActionController::Base, ActionController::API]
            controller.class_eval do
              include ExtRails::WithExceptions
            end
          end
        end
      end
    end

    config.after_initialize do |app|
      (Rails::Engine.subclasses.map(&:root) << Rails.root).each do |root|
        Dir[root.join("{app,lib}/**/*_decorator.rb")].each do |c|
          require_dependency(c)
        end
      end

      app.routes.append do
        match '/' => 'application#healthcheck', via: :head

        match '*not_found', via: %w[ get post put patch delete head options any ], to: 'application#render_404'
      end
    end
  end
end
