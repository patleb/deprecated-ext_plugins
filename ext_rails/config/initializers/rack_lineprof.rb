if Rails.root.join('tmp/profiler.txt').exist?
  require 'rack_lineprof'

  app.middleware.use ::Rack::Lineprof, profile: ExtRails.config.profile
end
