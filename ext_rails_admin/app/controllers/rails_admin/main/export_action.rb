module RailsAdmin
  module Main
    module ExportAction
      def export
        if format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
          request.format = format
          @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).to_unsafe_h) if params[:schema] # to_json and to_xml expect symbols for keys AND values.
          @objects = list_entries(@model_config, :export)
          serve_action :index
        else
          render @action.template_name
        end
      end
    end
  end
end
