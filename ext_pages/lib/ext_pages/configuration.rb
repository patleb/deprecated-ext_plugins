module ExtPages
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
    attr_accessor :skip_migrations
    attr_writer :pages_config_path
    attr_writer :parent_model
    attr_writer :parent_controller
    attr_writer :reserved_words
    attr_writer :polymorphic_tables

    def pages_config_path
      @pages_config_path ||= Rails.root.join('config/pages.yml')
    end

    def parent_model
      @parent_model ||= '::ActiveRecord::Base'
    end

    def parent_controller
      @parent_controller ||= '::ActionController::Base'
    end

    def reserved_words
      @reserved_words ||= %w(new edit index session login logout users admin stylesheets assets javascripts images)
    end

    def polymorphic_tables
      @polymorphic_tables ||= %w(pages contents)
    end
  end
end
