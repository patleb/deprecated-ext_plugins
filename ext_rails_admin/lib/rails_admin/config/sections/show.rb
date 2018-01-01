module RailsAdmin
  module Config
    module Sections
      class Show < RailsAdmin::Config::Sections::Base
        register_instance_option :report? do
          false
        end

        register_instance_option :report_name do
          "#{@abstract_model.param_key}_report-#{m.send(@abstract_model.config.object_label_method).dehumanize}"
        end

        register_instance_option :report_template do
          "rails_admin/reports/#{@abstract_model.param_key}_report"
        end

        register_instance_option :report_layout do
          "layouts/rails_admin/reports"
        end

        register_instance_option :report_options do
          {
            # show_as_html: false,
            # ~792px
            page_size: 'Letter',
            margin: {
              top: '10mm', bottom: '10mm', right: '2mm', left: '2mm'
            }
          }
        end
      end
    end
  end
end
