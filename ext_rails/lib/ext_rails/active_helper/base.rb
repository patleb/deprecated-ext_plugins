module ActiveHelper
  class Base
    attr_accessor :view

    def self.[](*instance_variables)
      base_class =
        case instance_variables.first
        when Symbol, String, nil
          self
        else
          instance_variables.shift
        end

      Class.new(base_class) do
        define_singleton_method :_instance_variables do
          super().merge(instance_variables)
        end
      end
    end

    def self._instance_variables
      Set.new
    end

    def initialize(view, *instance_variables)
      self.view = view

      (instance_variables.presence || self.class._instance_variables).each do |instance_variable_symbol|
        instance_variable_set(instance_variable_symbol, view.instance_variable_get(instance_variable_symbol))
      end

      after_initialize
    end

    def after_initialize; end

    def method_missing(name, *args, &block)
      view.__send__(name, *args, &block)
    end

    def respond_to_missing?(name, include_private = false)
      view.respond_to?(name, include_private) || super
    end
  end
end
