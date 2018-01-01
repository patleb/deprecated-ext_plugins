module RailsAdmin
  module Main
    module HistoryShowAction
      def history_show
        @general = false
        @history = @auditing_adapter && @auditing_adapter.listing_for_object(@abstract_model, @object, params[:query], params[:sort], params[:sort_reverse], params[:all], params[:page]) || []

        render @action.template_name
      end
    end
  end
end
