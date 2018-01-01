module ExtTasks
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
    attr_accessor :keep_install_migrations
    attr_accessor :tasks_included
    attr_accessor :tasks_excluded
    attr_writer :output_length
    attr_writer :parent_model
    attr_writer :parent_async

    def tasks_visible
      @_tasks ||= begin
        require 'rake'

        tasks = Rails.application.all_rake_tasks

        if tasks_included
          included = tasks_included.map(&:to_s)
          tasks = tasks.select{ |name, _task| name.to_s.in? included }
        end

        if tasks_excluded
          excluded = tasks_excluded.map(&:to_s)
          tasks = tasks.reject{ |name, _task| name.to_s.in? excluded }
        end

        tasks
      end
    end

    def output_length
      @output_length ||= 80
    end

    def parent_model
      @parent_model ||= '::ActiveType::Object'
    end

    def parent_async
      @parent_async ||= '::AsyncController'
    end
  end
end
