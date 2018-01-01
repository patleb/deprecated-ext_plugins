ActionController::Base.class_eval do
  module WithUser
    def set_current
      super
      Current.user ||= User::Null.new
    end

    def with_context
      super do
        # TODO and controller_name is RailsAdmin scoped or other defined as configuration...?
        if %w(new edit).include?(action_name) && request.method == 'POST'
          Logidze.with_responsible(Current.user.id) do
            yield
          end
        else
          yield
        end
      end
    end
  end
  prepend WithUser
end
