module ActivePresenter
  class BaseList
    include Enumerable

    attr_accessor :view
    attr_accessor :list
    @@active_presenters = {}
    @@active_list_presenters = {}

    def self.cast(view:, type:, list:, **options)
      klass = presenter_list_candidates(type.name).lazy.map{ |name| active_presenter_list_class(name) }.find(&:present?)
      klass ||= BaseList
      klass.new(view: view, type: type, list: list, **options)
    end

    def initialize(view:, type:, list:, **options)
      self.view = view
      # TODO wildcard, then candidate name is dependent only on element class name and its ancestors
      self.list = list.map do |model|
        klass = model.class
        klass = [klass].concat(klass.parents).lazy.map(&:name).map{ |name| active_presenter_class(name) }.find(&:present?)
        klass ||= Base
        klass.new(view: view, model: model, **options)
      end
    end

    def each
      list.each do |item|
        yield item
      end
      self
    end

    def method_missing(name, *args, &block)
      view.__send__(name, *args, &block)
    end

    def respond_to_missing?(name, include_private = false)
      view.respond_to?(name, include_private) || super
    end

    private

    def self.presenter_list_candidates(name)
      (scopes = name.split('::')).map.with_index do |_scope, i|
        scopes[0..(-1 - i)].join('::')
      end
    end

    def self.active_presenter_list_class(name)
      klass = "#{name}ListPresenter"
      if @@active_list_presenters.has_key? klass
        @@active_list_presenters[klass]
      else
        @@active_list_presenters[klass] = klass.constantize
      end
    rescue NameError, LoadError
      @@active_list_presenters[klass] = nil
    end

    def active_presenter_class(name)
      klass = "#{name}Presenter"
      if @@active_presenters.has_key? klass
        @@active_presenters[klass]
      else
        @@active_presenters[klass] = klass.constantize
      end
    rescue NameError, LoadError
      @@active_presenters[klass] = nil
    end
  end
end
