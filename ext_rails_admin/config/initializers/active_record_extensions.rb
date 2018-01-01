ActiveSupport.on_load(:active_record) do
  module ActiveRecord
    class Base
      def self.rails_admin(&block)
        RailsAdmin.config(self, &block)
      end

      def self.to_admin_param(model_name = nil)
        (model_name || name).split('::').collect(&:underscore).join(RailsAdmin::Config::NAMESPACE_SEPARATOR)
      end

      def rails_admin_default_object_label_method
        new_record? ? "new #{self.class}" : "#{self.class} ##{id}"
      end

      def safe_send(value)
        if has_attribute?(value)
          # TODO https://github.com/bbatsov/rails-style-guide/issues/155
          self[value]
        else
          send(value)
        end
      end
    end
  end
end
