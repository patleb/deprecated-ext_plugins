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
      return [] unless @objects.exists?

      if (estimate = @objects.count_estimate) > RailsAdmin.config.chart_max_rows
        raise RailsAdmin::TooManyRows.new("Too many rows: #{estimate} > #{RailsAdmin.config.chart_max_rows}")
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
        query = adjust_query_count(query)
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
      resolution = automatic_resolution(query, group_by)

      if @chart_config.with_time_zone?
        # TODO time zone
      else
        group_base = "(DATE_TRUNC('#{resolution}', #{group_by}))"
        group_name = "date_trunc_#{resolution.underscore}_#{group_by.to_s.underscore.tr('.', '_')}"
        query = query.reorder(nil).group(group_base).order(group_name)
      end

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
      resolution_ratio = @chart_config.resolution_ratio

      resolution = 'second'
      if seconds > (max_size * 60 / resolution_ratio)
        resolution = 'minute'
        if (minutes = seconds / 60) > (max_size * 60 / resolution_ratio)
          resolution = 'hour'
          if (_hours = minutes / 60) > (max_size * 24 / resolution_ratio)
            resolution = 'day'
          end
        end
      end

      resolution
    end

    def adjust_query_count(query)
      max_size = @chart_config.max_size

      if max_size && (size = query.count) > max_size
        chunk_size = (size / max_size.to_f).ceil
        result = {}
        query.each_slice(chunk_size) do |segment|
          start, first = segment.first
          finish, last = segment.last
          aggregation =
            if first.nil? || last.nil?
              nil
            else
              case @calculation
              when :count, :sum then segment.sum{ |item| item.last }
              when :average     then segment.sum{ |item| item.last } / segment.count.to_f
              when :minimum     then segment.min_by{ |item| item.last }.last
              when :maximum     then segment.max_by{ |item| item.last }.last
              end
            end
          timestamp = start + ((finish - start) / 2).to_i
          result[timestamp] = aggregation
        end
        query = result
      end

      query
    end

    def map_query_values(query)
      if (map = @chart_config.map)
        query = if map.is_a? Proc
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
