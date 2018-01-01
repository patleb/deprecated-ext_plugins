module RailsAdmin
  module Main
    module HistoryIndexAction
      def history_index
        @general = true
        @history = @auditing_adapter && @auditing_adapter.listing_for_model(@abstract_model, params[:query], params[:sort], params[:sort_reverse], params[:all], params[:page]) || []

        render @action.template_name
      end
    end
  end
end
