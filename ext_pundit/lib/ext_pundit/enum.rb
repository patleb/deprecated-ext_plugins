module ExtPundit
  module Enum
    extend ActiveSupport::Concern

    class_methods do
      def enum(klass, name, *values)
        list = klass.try("#{name}_i18n") || klass.send(name)
        list = list.slice(*values) if values.any?
        list.invert
      end
    end
  end
end
