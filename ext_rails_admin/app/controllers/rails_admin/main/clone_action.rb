module RailsAdmin
  module Main
    module CloneAction
      def clone
        respond_to do |format|
          format.html { render @action.template_name }
          format.js   { render @action.template_name, layout: false }
        end
      end
    end
  end
end
