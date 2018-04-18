module VirtualType
  extend ActiveSupport::Concern

  included do
    # TODO association proxy
    list_class = Class.new(Array) do
      def page(*_);       self end
      def per(*_);        self end
      def reorder(*_);    self end
      def references(*_); self end
      def merge(*_);      self end

      def where(query, *params)
        if query.is_a? Hash
          name = query['id'] || query[:id]
          return self.class.new([find{ |task| task.id == name }])
        end
        if params.empty?
          return self
        end

        text = params.last.gsub(/(^%|%$)/, '').downcase

        attributes = query.split('OR').map{ |attr| attr.gsub(/(^ ?\(objects\.| ILIKE \?\) ?$)/, '') }

        self.class.new(select{ |task| attributes.any?{ |attr| task.send(attr).to_s.downcase.include?(text) } })
      end
    end
    const_set('List', list_class)

    attribute :id
  end

  def persisted?
    true
  end

  class_methods do
    def find(id)
      unless (object = all.where(id: id).first)
        raise ::ActiveRecord::RecordNotFound
      end

      object
    end

    def all
      raise NotImplementedError
    end
  end
end
