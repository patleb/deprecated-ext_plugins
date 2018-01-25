class PageListPresenter < ContentListPresenter
  attr_accessor :skip_cache

  def initialize(skip_cache:, **options)
    super
    @page = first
    self.skip_cache = skip_cache
  end

  def method_missing(name, *args, &block)
    if @page.respond_to? name
      @page.__send__(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    @page.respond_to?(name, include_private) || super
  end
end
