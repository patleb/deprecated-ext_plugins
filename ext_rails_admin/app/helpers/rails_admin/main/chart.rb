module RailsAdmin
  module Main
    class Chart < Base
      delegate :refresh_rate, to: :chart_config

      def render
        options = {}
        source = if params[:chart_data]
          if chart_form[:auto_refresh].to_b
            options[:refresh] = refresh_rate
          end
          chart_path(params.slice(:model_name, :scope, :query, :f, :c).merge(all: true, chart_data: true, chart_form: chart_form_defaults))
        else
          []
        end
        chartkick chart_config.type, source, chart_config.options.merge(options)
      end

      def field_options
        result = {}
        visible_fields.select{ |f| !f.association? || f.association.polymorphic? }.each do |field|
          list = field.virtual? ? 'methods' : 'only'
          if field.association? && field.association.polymorphic?
            result["#{field.label} [id]"] = "schema[#{list}][#{field.method_name}]"
            polymorphic_type_column_name = @abstract_model.properties.find{ |p| field.association.foreign_type == p.name }.name
            result["#{capitalize_first_letter(field.label)} [type]"] = "schema[#{list}][#{polymorphic_type_column_name}]"
          else
            result[capitalize_first_letter(field.label)] = "schema[#{list}][#{field.name}]"
          end
        end
        visible_fields.select{ |f| f.association? && !f.association.polymorphic? }.each do |field|
          object = (field.associated_model_config.abstract_model.model).new
          fields = field.associated_model_config.chart.with(controller: controller, view: view, object: object).visible_fields.reject(&:association?)
          fields.each do |associated_model_field|
            list = associated_model_field.virtual? ? 'methods' : 'only'
            result[capitalize_first_letter(associated_model_field.label)] = "schema[include][#{field.name}][#{list}][#{associated_model_field.name}]"
          end
        end
        options_for_select(result, field_default)
      end

      def calculation_options
        options_for_select(%i[
          count
          average
          minimum
          maximum
          sum
        ], calculation_default)
      end

      def field_default
        chart_form[:field] || begin
          field_name = chart_config.field_default
          if field_name
            field = visible_fields.find{ |f| f.name == field_name }
            "schema[#{field.virtual? ? 'methods' : 'only'}][#{field_name}]"
          end
        end
      end

      def calculation_default
        chart_form[:calculation] || :average
      end

      def auto_refresh_default
        chart_form[:auto_refresh].to_b
      end

      def form_path
        chart_path(params.slice(:model_name, :scope).merge(all: true))
      end

      def params
        @_params ||= super.to_unsafe_h.slice(:model_name, :scope, :query, :f, :c, :chart_data, :chart_form)
      end

      def ordered_chart_string
        ordered_charts.to_json
      end

      private

      def ordered_charts
        @_ordered_charts ||= (params[:c] || {}).to_a.sort_by(&:first).each_with_object({}) do |(index, inputs), memo|
          inputs.each do |(name, value)|
            case name
            when 'field'
              field = chart_field_for(value.match(/\[(\w+)\]$/)[1])
              label_name = t('admin.chart.field')
              label_value = field.label
            when 'calculation'
              label_name = t('admin.chart.calculation')
              label_value = value
            else
              field = chart_field_for(value)
              label_name = field.label
              label_value = value.to_s
            end
            memo[index] ||= []
            memo[index] << {
              index: index,
              input: { name: name, value: value },
              label: { name: label_name, value: label_value }
            }
          end
        end
      end

      def chart_field_for(name)
        visible_fields.find{ |f| f.name == name.to_sym }
      end

      def chart_form_defaults
        {
          field: field_default,
          calculation: calculation_default,
          auto_refresh: auto_refresh_default,
        }
      end

      def chart_form
        @_chart_form ||= params[:chart_form] || {}
      end

      def chart_config
        @_chart_config ||= @model_config.chart.with(controller: controller, view: view)
      end

      def visible_fields
        @_visible_fields ||= chart_config.with(view: view, object: @abstract_model.model.new, controller: controller).visible_fields
      end
    end
  end
end
