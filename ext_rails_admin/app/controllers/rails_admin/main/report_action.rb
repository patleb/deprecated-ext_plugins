module RailsAdmin
  module Main
    module ReportAction
      def report
        config = @model_config.show.with(controller: self, object: @object)
        render config.report_options.reverse_merge(
            pdf: config.report_name,
            template: config.report_template,
            layout: config.report_layout
          )
      end
    end
  end
end
