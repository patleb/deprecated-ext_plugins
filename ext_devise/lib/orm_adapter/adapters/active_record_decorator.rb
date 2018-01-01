module OrmAdapter
  ActiveRecord.class_eval do
    def get(id)
      Current.user = klass.unscoped.where(id: id).take
    end

    def find_first(options = {})
      construct_relation(klass.unscoped, options).take
    end
  end
end
