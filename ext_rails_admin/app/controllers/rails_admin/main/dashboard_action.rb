module RailsAdmin
  module Main
    module DashboardAction
      def dashboard
        @history = @auditing_adapter && @auditing_adapter.latest || []
        if @action.statistics?
          @abstract_models = RailsAdmin::Config.visible_models(controller: self).collect(&:abstract_model)

          @most_recent_created = {}
          @count = {}
          @max = 0
          @abstract_models.each do |t|
            scope = @authorization_adapter && @authorization_adapter.query(:index, t)
            current_count = t.count({}, scope)
            @max = current_count > @max ? current_count : @max
            @count[t.model.name] = current_count
            next unless t.properties.detect { |c| c.name == :created_at }
            @most_recent_created[t.model.name] = t.model.last.try(:created_at)
          end
        end
        render @action.template_name, status: @status_code || :ok
      end
    end
  end
end
