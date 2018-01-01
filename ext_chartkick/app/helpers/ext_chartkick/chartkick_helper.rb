module ExtChartkick
  module ChartkickHelper
    SUPPORTED_CHARTS = Set.new(%w(
      line
      pie
      column
      bar
      area
      scatter
      geo
      timeline
    ))

    def chartkick(type, data_source, options)
      type = type.to_s
      raise "unsupported chart type [#{type}]" unless SUPPORTED_CHARTS.include?(type)

      @chartkick_chart_id ||= 0
      options = Chartkick.options.deep_merge(options)
      element_id = options.delete(:id) || "chart-#{@chartkick_chart_id += 1}"
      height = options.delete(:height) || "300px"
      width = options.delete(:width) || "100%"
      html = (options.delete(:html) || %(<div id="%{id}" style="height: %{height}; width: %{width}; text-align: center; color: #999; line-height: %{height}; font-size: 14px; font-family: 'Lucida Grande', 'Lucida Sans Unicode', Verdana, Arial, Helvetica, sans-serif;">Loading...</div>)) % {id: ERB::Util.html_escape(element_id), height: ERB::Util.html_escape(height), width: ERB::Util.html_escape(width)}

      createjs = {
        type: "#{type.camelize}#{'Chart' unless type == 'timeline'}",
        id: element_id,
        source: data_source.respond_to?(:chart) ? data_source.chart : data_source,
        options: options,
      }
      html += "<div class='js_chartkick_config' data-js='#{createjs.to_json}'></div>"
      html.html_safe
    end
  end
end
