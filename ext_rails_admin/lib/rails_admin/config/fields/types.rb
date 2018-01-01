module RailsAdmin
  module Config
    module Fields
      module Types
        @@registry = {}

        def self.load(type)
          @@registry[type.to_sym] || raise("Unsupported field datatype: #{type}")
        end

        def self.register(type, klass = nil)
          if klass.nil? && type.is_a?(Class)
            klass = type
            type = klass.name.to_s.demodulize.underscore
          end
          @@registry[type.to_sym] = klass
        end
      end
    end
  end
end
