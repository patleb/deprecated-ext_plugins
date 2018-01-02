AsyncJob.class_eval do
  module WithUser
    def perform(url, **context)
      context.merge! _user_id: Current.user&.id
      super
    end
  end
  prepend WithUser
end
