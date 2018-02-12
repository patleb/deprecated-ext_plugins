module RailsAdmin
  module Config
    module Fields
      module Types
        class Date < RailsAdmin::Config::Fields::Types::Datetime
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :date_format do
            :long
          end

          register_instance_option :i18n_scope do
            [:date, :formats]
          end

          register_instance_option :datepicker_options do
            {
              ignoreReadonly: true,
              showTodayButton: true,
              format: parser.to_momentjs,
            }
          end

          register_instance_option :html_attributes do
            {
              readonly: true,
              required: required?,
              size: 18,
            }
          end
        end
      end
    end
  end
end
