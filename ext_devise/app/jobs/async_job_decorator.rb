AsyncJob.class_eval do
  module WithUser
    def perform(url, wait: nil, _now: nil, _type: 'job', **context)
      context.merge! _user_id: Current.user&.id
      super
    end
  end
  prepend WithUser
end
