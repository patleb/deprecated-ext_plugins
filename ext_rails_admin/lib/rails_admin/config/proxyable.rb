module RailsAdmin
  module Config
    module Proxyable
      class Proxy < BasicObject
        attr_reader :bindings

        def initialize(object, bindings = {})
          @object = object
          @bindings = bindings
        end

        # Bind variables to be used by the configuration options
        def bind(key, value = nil)
          if key.is_a?(::Hash)
            @bindings = key
          else
            @bindings[key] = value
          end
          self
        end

        def method_missing(name, *args, &block)
          if @object.respond_to?(name)
            reset = @object.instance_variable_get('@bindings')
            begin
              @object.instance_variable_set('@bindings', @bindings)
              response = @object.__send__(name, *args, &block)
            ensure
              @object.instance_variable_set('@bindings', reset)
            end
            response
          else
            super(name, *args, &block)
          end
        end
      end

      attr_accessor :bindings

      def with(bindings = {})
        RailsAdmin::Config::Proxyable::Proxy.new(self, bindings)
      end

      def view
        bindings[:view]
      end

      def controller
        bindings[:controller]
      end

      def model
        bindings[:object]
      end
      alias_method :m, :model

      def form
        bindings[:form]
      end

      def method_missing(name, *args, &block)
        return super unless bindings

        if view.respond_to? name
          view.__send__(name, *args, &block)
        else
          controller.__send__(name, *args, &block)
        end
      end

      def respond_to_missing?(name, include_private = false)
        return super unless bindings

        view.respond_to?(name, include_private) || controller.respond_to?(name, include_private) || super
      end
    end
  end
end
