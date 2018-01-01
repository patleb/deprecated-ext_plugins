module ExtRails
  module WithActiveHelper
    extend ActiveSupport::Concern

    included do
      attr_accessor :template_virtual_path
      helper_method :active_helper_class
      @@active_helpers = {}
    end

    def active_helper_class
      klass = template_virtual_path.camelize
      if @@active_helpers.has_key? klass
        @@active_helpers[klass]
      else
        @@active_helpers[klass] = klass.constantize
      end
    rescue NameError, LoadError
      @@active_helpers[klass] = nil
    end
  end
end
