require 'active_type/virtual_attributes'
require "ext_rails/active_type/type_caster"
require "ext_rails/active_type/virtual_attributes"

module ActiveType
  Object.class_eval do
    def type_for_attribute(attribute)
      virtual_columns_hash[attribute]
    end
  end
end
