module ExtSettings
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
    attr_accessor :settings_included
    attr_accessor :settings_excluded
    attr_accessor :history_show_limite
    attr_writer :parent_model

    def settings_visible
      @_settings ||= begin
        settings = Setting.all.pluck(:id)

        if settings_included
          included = settings_included.map(&:to_s)
          settings = settings.select{ |name| name.in? included }
        end

        if settings_excluded
          excluded = settings_excluded.map(&:to_s)
          settings = settings.reject{ |name| name.in? excluded }
        end

        settings
      end
    end

    def history_show_limit
      if @history_show_limit
        (@history_show_limit < 20) ? @history_show_limit : 20
      else
        @history_show_limit = 10
      end
    end

    def parent_model
      @parent_model ||= '::ActiveRecord::Base'
    end
  end
end
