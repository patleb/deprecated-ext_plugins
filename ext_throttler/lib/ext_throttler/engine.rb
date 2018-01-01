require "ext_throttler/configuration"

module ExtThrottler
  class Engine < ::Rails::Engine
    require 'ext_rails'
    require "ext_globals"
  end
end
