module RailsAdmin
  module Main
    class FilterBox < Base
      def index_action?
        action_name == 'index'
      end

      def query?
        @model_config.list.query?
      end

      def ordered_filter_string
        ordered_filters.map do |(index, filter_for_field)|
          options = { index: index }
          filter_name, filter_hash = filter_for_field.first
          unless (field = filterable_fields.find { |f| f.name == filter_name.to_sym })
            raise "#{filter_name} is not currently filterable; filterable fields are #{filterable_fields.map(&:name).join(', ')}"
          end
          case field.type
          when :enum
            options[:select_options] = options_for_select(field.with(controller: controller, object: @abstract_model.model.new).enum, filter_hash['v'])
          when :date, :datetime, :time
            options[:datetimepicker_format] = field.parser.to_momentjs
          end
          options[:label] = field.label
          options[:name]  = field.name
          options[:type]  = field.type
          options[:value] = filter_hash['v']
          options[:label] = field.label
          options[:operator] = filter_hash['o']
          options
        end.to_json
      end

      def filterable_fields
        @filterable_fields ||= @model_config.list.fields.select(&:filterable?)
      end

      def filter_options(field)
        field_options = if field.type == :enum
          options_for_select(field.with(controller: controller, object: @abstract_model.model.new).enum)
        else
          ''
        end
        {
          label: field.label,
          name: field.name,
          options: field_options.html_safe,
          type: field.type,
          value: "",
          datetimepicker_format: (field.try(:parser) && field.parser.to_momentjs)
        }.to_json
      end

      def form_path
        # TODO index_path(params: super.to_unsafe_h.slice(:model_name, :scope, :sort, :sort_reverse), anchor: 'js_filter_box_container')
        index_path(params.to_unsafe_h.slice(:model_name, :scope, :sort, :sort_reverse))
      end

      private

      def ordered_filters
        current_index = 0
        (params[:f].try(:to_unsafe_h) || @model_config.list.filters).reduce({}) do |memo, filter|
          field_name = filter.is_a?(Array) ? filter.first : filter
          (filter.is_a?(Array) ? filter.last : {(current_index += 1) => {'v' => ''}}).each do |index, filter_hash|
            if filter_hash['disabled'].blank?
              memo[index] = {field_name => filter_hash}
            else
              params[:f].delete(field_name)
            end
          end
          memo
        end.to_a.sort_by(&:first)
      end
    end
  end
end
