module ActivePresenter
  class Base
    attr_accessor :view
    attr_accessor :model

    def initialize(view:, model:, **options)
      self.view = view
      self.model = model
    end

    def method_missing(name, *args, &block)
      if view.respond_to? name
        view.__send__(name, *args, &block)
      else
        model.__send__(name, *args, &block)
      end
    end

    def respond_to_missing?(name, include_private = false)
      view.respond_to?(name, include_private) || model.respond_to?(name, include_private) || super
    end
  end
end
