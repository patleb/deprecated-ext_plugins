module RailsAdmin
  module Config
    module Proxyable
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
