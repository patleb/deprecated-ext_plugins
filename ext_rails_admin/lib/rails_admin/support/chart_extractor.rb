module RailsAdmin
  class ChartExtractor
    attr_accessor :controller
    delegate :params, to: :controller

    def initialize(controller, abstract_model, objects)
      return self if (@objects = objects).nil?

      self.controller = controller
      @abstract_model = abstract_model
      @model_config = @abstract_model.config
    end

    def extract_charts
      if (estimate = @objects.count_estimate) > RailsAdmin.config.chart_max_rows
        raise RailsAdmin::TooManyRows.new("Too many rows: #{estimate} (max: #{RailsAdmin.config.chart_max_rows})")
      elsif estimate == 0
        return []
      end

      charts = if params.has_key? :c
        params[:c].to_unsafe_h.each_with_object([]) do |(_index, chart_form), forms|
          forms << [chart_form[:field], chart_form[:calculation]]
        end
      elsif params.has_key? :chart_form
        chart_form = params[:chart_form]
        [[chart_form[:field], chart_form[:calculation]]]
      else
        []
      end

      charts.map! do |(field, calculation)|
        prepare(field, calculation)
        execute
      end

      assign_right_y_axis(charts)
      charts
    end

    private

    def prepare(field, calculation)
      @calculation = calculation.try(:to_sym)

      field_param = Rack::Utils.parse_nested_query(field).with_indifferent_access
      schema = HashHelper.symbolize(field_param[:schema].slice(:except, :include, :methods, :only).to_h)

      method = (schema[:only] || schema[:methods]).first[0]
      @field = chart_field_for(method, @model_config).first
      @chart_config = @model_config.chart.with(controller: controller, chart_field: method)
      schema_include = schema.delete(:include) || {}
      name, values = schema_include.first

      return if @field || name.nil?

      association = association_for(name, @model_config)
      association_method = (values[:only] || values[:methods]).first[0]
      association_model_config = association.associated_model_config

      @association = { name => {
        abstract_model: association_model_config.abstract_model,
        field: chart_field_for(association_method, association_model_config).first,
        chart_config: association_model_config.chart.with(controller: controller)
      } }
    end

    def execute
      query = @objects
      if @field && @chart_config.group_by
        query = run_query(query)
        query = map_query_values(query)
      elsif @association
        association_name, option_hash = @association.first
        query = query.include(association_name)
      end
      { name: "#{@field.label} - #{@calculation}", data: query }
    end

    def assign_right_y_axis(charts)
      maxes = charts.map do |chart|
        chart[:data].max_by{ |item| item.last&.abs }.last&.abs
      end
      max = maxes.compact.max
      smaller_max = max ? max / @chart_config.y2_ratio : 0

      charts.each_with_index do |chart, i|
        max = maxes[i]
        if max.nil? || max < smaller_max
          chart[:y2] = true
        end
      end
    end

    def association_for(name, model_config)
      chart_field_for(name, model_config).find(&:association?)
    end

    def chart_field_for(method, model_config)
      model_config.chart.fields.select{ |f| f.name == method }
    end

    def run_query(query)
      group_by = @chart_config.group_by

      group_base, group_name = automatic_resolution(query, group_by)
      query = query.reorder(nil).group(group_base).order(group_name)

      field_name = @field.name
      model, select_method = @abstract_model.model, "chart_#{field_name}"
      if model.respond_to? select_method
        field_name = model.send select_method
      end

      if (work_mem = @chart_config.work_mem)
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute("SET LOCAL work_mem = '#{work_mem}MB'")
          query.send(@calculation, field_name)
        end
      else
        query.send(@calculation, field_name)
      end
    end

    def automatic_resolution(query, group_by)
      group_by = group_by.to_s.split('.').last
      first, last = query.first.send(group_by), query.last.send(group_by)
      first, last = last, first if first > last
      seconds = (last - first).to_i
      max_size = @chart_config.max_size
      chunk_size = (seconds / max_size.to_f).ceil

      sql = <<~SQL
        to_timestamp(FLOOR((EXTRACT('epoch' FROM #{group_by}) / #{chunk_size} )) * #{chunk_size}) AT TIME ZONE 'UTC'
      SQL
      [sql, "to_timestamp_floor_extract_epoch_from_#{group_by}_#{chunk_size}_all_#{chunk_size}_at_time_zone_utc"[0..62]]
    end

    def map_query_values(query)
      if (map = @chart_config.map)
        query =
          if map.is_a? Proc
            query.map(&map)
          else
            method, *args = Array.wrap(map)
            query.map do |group_by_value|
              group_by_value[1] = group_by_value[1].send(method, *args)
              group_by_value
            end
        end
      end

      query
    end
  end
end
