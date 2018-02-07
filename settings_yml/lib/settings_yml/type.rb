require 'chronic_duration'

module SettingsYml::Type
  extend ActiveSupport::Concern

  class_methods do
    def cast(value, type)
      type = type.to_s
      if type == 'emails'
        value&.split(/[\s,;]/)&.reject(&:blank?)
      elsif type.end_with? 's'
        type = type.chop
        (value || '').split(',').map!{ |element| cast(element.strip, type) }
      else
        case type&.to_sym
        when :json
          JSON.parse(value).with_indifferent_access
        when :boolean
          value.to_b
        when :integer
          value.to_i
        when :decimal
          BigDecimal.new(value)
        when :datetime
          DateTime.parse(value)
        when :interval
          ActiveSupport::Duration.build(ChronicDuration.parse(value || '', keep_zero: true))
        else
          value
        end
      end
    end
  end
end
