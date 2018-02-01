Mobility::Attributes.class_eval do
  module WithTextOnly
    def included(klass)
      klass.class_eval do
        def mobility_destroy_key_value_translations
          ::Translation.where(translatable: self).destroy_all
        end
      end

      super
    end
  end
  prepend WithTextOnly
end
