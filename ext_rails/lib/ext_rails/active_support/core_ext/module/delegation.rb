Module.class_eval do
  def delegate_to(to, *methods, **options)
    options = options.merge(to: to)

    as_protected = options.delete(:protected)
    as_private = options.delete(:private)

    if options.delete(:writer)
      writers = methods.map{ |method| :"#{method}=" }

      delegate(*writers, options)
    end

    delegate(*methods, options)

    if (prefix = options[:prefix])
      methods = methods.map{ |name| "#{prefix == true ? options[:to] : prefix}_#{name}" }
    end

    protected *methods if as_protected
    private *methods if as_private
  end
end
