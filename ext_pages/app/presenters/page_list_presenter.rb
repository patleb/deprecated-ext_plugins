class PageListPresenter < ContentListPresenter
  def initialize(**options)
    super
    @page = first
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
