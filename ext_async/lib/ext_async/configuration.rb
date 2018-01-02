module ExtAsync
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
    attr_writer :parent_model
    attr_writer :parent_task
    attr_writer :parent_controller
    attr_writer :inline
    attr_writer :allowed_ips
    attr_writer :min_pool_size
    attr_writer :flash_expires_in

    def parent_model
      @parent_model ||= '::ActiveRecord::Base'
    end

    def parent_task
      @parent_task ||= '::ActiveTask::Base'
    end

    def parent_controller
      @parent_controller ||= '::ActionController::Base'
    end

    def inline?
      return @inline if defined? @inline

      @inline = (Rails.env.development? || Rails.env.test?)
    end

    def allowed_ips
      @allowed_ips ||= [Rails.application.remote_ip]
    end

    def min_pool_size
      @min_pool_size ||= (SettingsYml[:max_pool_size]&.to_i || 6) - 2
    end

    def flash_expires_in
      @expires_in ||= 1.day
    end
  end
end
