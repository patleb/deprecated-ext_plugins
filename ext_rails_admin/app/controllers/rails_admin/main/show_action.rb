module RailsAdmin
  module Main
    module ShowAction
      def show
        respond_to do |format|
          format.json { render json: @object }
          format.html { render @action.template_name }
        end
      end
    end
  end
end
