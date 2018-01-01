if (Rails.env.development? || Rails.env.test?) && defined?(::WEBrick)
  # Stop all the /assets/ logs in the webrick stdout
  require 'webrick/httpserver.rb'
  WEBrick::HTTPServer.class_eval do
    def access_log(config, req, res)
      # so assets don't log
    end
  end

  require 'rack/handler/webrick.rb'
  Rack::Handler::WEBrick.class_eval do
    def self.shutdown
      @server&.shutdown
      @server = nil
    end
  end
end
