module ExtRails
  module WithDispatch
    extend ActiveSupport::Concern
    
    class_methods do
      def dispatch_now(url, params: {}, request_params: {}, session: nil)
        params = params.with_indifferent_access
        if request_params.has_key? :_method
          params[:method] = request_params[:_method] || 'post'
        end
        http_method = (params[:method] ||= :get).to_s.upcase
        uri, query_params = parse_url(url)
        path_params = recognize_path(uri.path, params.merge!(query_params))

        controller_name = "#{path_params[:controller].underscore.camelize}Controller"
        controller      = ActiveSupport::Dependencies.constantize(controller_name)
        action          = path_params[:action] || 'index'
        request_env     = {
          'rack.input' => '',
          'QUERY_STRING' => uri.query,
          'REQUEST_METHOD' => http_method,
          'REQUEST_PATH' => uri.path,
          'REQUEST_URI' => url,
          'PATH_INFO' => uri.path,
          'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest',
          'SERVER_NAME' => uri.hostname,
          'SERVER_PORT' => uri.port,
          'SERVER_PROTOCOL' => 'HTTP/1.1',
          'rack.url_scheme' => uri.scheme,
          'action_dispatch.remote_ip' => Rails.application.remote_ip,
          'action_dispatch.request.query_parameters' => query_params,
          'action_dispatch.request.request_parameters' => request_params,
          'action_dispatch.request.path_parameters' => path_params,
          'action_dispatch.request.parameters' => params.merge!(request_params).merge!(path_params),
        }
        request_env['rack.session'] = session if session
        request = ActionDispatch::Request.new(request_env)
        response = controller.make_response! request

        controller.dispatch(action, request, response) # [status, headers, body]
      end

      def merge_url(url, params, hostname: nil)
        uri, query_params = parse_url(url)
        port = [80, 443].exclude?(uri.port) ? ":#{uri.port}" : ''
        query_params.merge!(params)
        query = query_params.any? ? "?#{query_params.to_param}" : ''

        [uri.scheme, '://', hostname || uri.hostname, port, uri.path, query].join
      end

      def parse_url(url)
        uri = URI.parse(url)
        query_params = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access

        [uri, query_params]
      end

      def recognize_path(path, options)
        recognized_path = Rails.application.routes.recognize_path(path, options)

      rescue ActionController::RoutingError => e
        unless e.message.start_with? 'No route matches'
          raise
        end

        Rails::Engine.subclasses.each do |engine|
          mounted_engine = Rails.application.routes.routes.find{ |r| r.app.app == engine }
          next unless mounted_engine

          path_for_engine = path.sub(/^#{mounted_engine.path.spec}/, '')
          begin
            recognized_path = engine.routes.recognize_path(path_for_engine, options)
            break
          rescue ActionController::RoutingError
            # do nothing
          end
        end

        recognized_path
      ensure
        unless recognized_path&.has_key? :controller
          raise ActionController::RoutingError, "No route matches [#{path}]"
        end
      end
    end
  end
end
