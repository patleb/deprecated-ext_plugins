module ExtMultiverse
  class Engine < ::Rails::Engine
    require 'ext_rails'
    require 'multiverse'

    config.before_initialize do
      if defined? PhusionPassenger
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          if forked
            # We're in smart spawning mode.
            ServerRecord.establish_connection :"server_#{Rails.env}"
          else
            # We're in direct spawning mode. We don't need to do anything.
          end
        end
      end
    end

    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.class_eval do
        include ExtMultiverse::WithQueryCache
      end

      ActionController::API.class_eval do
        include ExtMultiverse::WithQueryCache
      end
    end
  end
end
