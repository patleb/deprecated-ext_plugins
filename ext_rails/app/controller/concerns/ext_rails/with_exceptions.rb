module ExtRails
  class Unknown < StandardError
  end

  class DbTimeout < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message =~ /PG::QueryCanceled/
    end
  end

  module WithExceptions
    extend ActiveSupport::Concern

    included do
      _process_action_callbacks.each do |callback|
        __send__ "skip_#{callback.kind}_action", callback.filter, only: [:render_404, :render_408, :render_500]
      end

      if ExtRails.config.rescue_500?
        rescue_from StandardError, Exception, with: :render_500
      end
      rescue_from ExtRails::DbTimeout, with: :render_408
    end

    def render_404
      # do not log these errors, they are already in nginx log
      respond_to do |format|
        format.html { render file: 'public/404.html', status: :not_found, layout: false }
        format.all  { head :not_found }
      end
    end

    def render_408(exception = Unknown.new)
      log exception, subject: :request_timeout
      respond_to do |format|
        format.html do
          self.response_body = nil # make sure that there is no DoubleRenderError
          if File.exist? Rails.root.join('public', '408.html')
            render file: 'public/408.html', status: :request_timeout, layout: false
          else
            render html: <<-HTML.strip_heredoc.html_safe, status: :request_timeout
              <!DOCTYPE html>
              <html>
              <head>
                <title>Timeout</title>
                <style type="text/css">
                  body {
                    width: 400px;
                    margin: 100px auto;
                    font: 300 120% "OpenSans", "Helvetica Neue", "Helvetica", Arial, Verdana, sans-serif;
                  }
  
                  h1 {
                    font-weight: 300;
                  }
                </style>
              </head>
              <body>
                <h1>Timeout</h1>
  
                <p>The request took too long</p>
  
                <p>Please retry or make a simpler request if it was an intensive one.</p>
              </body>
              </html>
            HTML
          end
        end
        format.all do
          if params[:send_data]
            output = 'Timeout: The request took too long, please retry or make a simpler request if it was an intensive one.'
            send_data output, type: 'text/plain', filename: 'request_timeout.txt'
          else
            head :request_timeout
          end
        end
      end
    end

    def render_500(exception = Unknown.new)
      log exception, subject: :internal_server_error
      respond_to do |format|
        format.html do
          self.response_body = nil # make sure that there is no DoubleRenderError
          render file: 'public/500.html', status: :internal_server_error, layout: false
        end
        format.all { head :internal_server_error }
      end
    end

    def healthcheck
      head :ok
    end
  end
end
