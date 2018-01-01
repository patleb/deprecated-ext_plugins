module Chartkick
  class << self
    attr_accessor :options
  end

  self.options = {
    responsive: true,
    height: '360px',
  }
end

# for multiple series
# use Enumerable so it can be called on arrays
module Enumerable
  def chart_json
    chart.to_json
  end

  def chart
    if is_a?(Hash) && (key = keys.first) && key.is_a?(Array) && key.size == 2
      group_by { |k, _v| k[0] }.map do |name, data|
        {name: name, data: data.map { |k, v| [k[1], v] }}
      end
    else
      self
    end
  end
end
