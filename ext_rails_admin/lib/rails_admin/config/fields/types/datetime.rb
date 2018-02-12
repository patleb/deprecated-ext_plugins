module RailsAdmin
  module Config
    module Fields
      module Types
        class Datetime < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          def parser
            @parser ||= RailsAdmin::Support::Datetime.new(strftime_format)
          end

          def parse_value(value)
            parser.parse_string(value)
          end

          def parse_input(params)
            params[name] = parse_value(params[name]) if params[name]
          end

          def value
            parent_value = super
            if %w(DateTime Date Time).include?(parent_value.class.name)
              parent_value.in_time_zone
            else
              parent_value
            end
          end

          register_instance_option :date_format do
            :long
          end

          register_instance_option :i18n_scope do
            [:time, :formats]
          end

          register_instance_option :strftime_format do
            begin
              ::I18n.t(date_format, scope: i18n_scope, raise: true)
            rescue ::I18n::ArgumentError
              "%B %d, %Y %H:%M"
            end
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
              size: 22,
            }
          end

          register_instance_option :sort_reverse? do
            true
          end

          register_instance_option :formatted_value do
            if time = (value || default_value)
              ::I18n.l(time, format: strftime_format)
            else
              ''.html_safe
            end
          end

          register_instance_option :render do
            div '.form-inline' do
              div '.input-group' do[
                form.send(view_helper, method_name, html_attributes.reverse_merge(
                  value: form_value,
                  class: 'form-control js_field_input js_datetimepicker',
                  data: { js: { showClear: true }.reverse_merge(datepicker_options).to_json }
                )),
                form.label(method_name, class: 'input-group-addon') do
                  i '.fa.fa-fw.fa-calendar'
                end
              ]end
            end
          end
        end
      end
    end
  end
end
