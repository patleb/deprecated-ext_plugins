module RailsAdmin
  module Main
    module ChartAction
      def chart
        if params[:chart_data]
          if request.get?
            request.format = :json
          end
          @objects = list_entries(@model_config, :chart)
          serve_action :index
        else
          render @action.template_name
        end
      end
    end
  end
end
