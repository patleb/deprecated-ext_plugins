# TODO make it work for API controllers

module ExtRails
  module WithContext
    extend ActiveSupport::Concern

    included do
      before_action :set_current
      around_action :with_context
    end

    def rescue_with_handler(exception)
      with_context do
        super
      end
    end

    def with_session?
      true
    end

    protected

    def set_current
      # TODO ip, user_agent
      Current.session_id ||= session.try(:id)
      Current.request_id ||= request.uuid
      set_current_value(:locale)
      set_current_value(:time_zone)
      set_current_value(:currency)
    end

    def with_context
      currency = Money.default_currency
      I18n.with_locale(Current.locale) do
        Time.use_zone(Current.time_zone) do
          MoneyRails.default_currency = Current.currency if Current.currency
          yield
        end
      end
    ensure
      MoneyRails.default_currency = currency
    end

    def set_current_value(name)
      Current[name] ||=
        if (value = params["_#{name}"]).present?
          if with_session?
            session[name] = value
          else
            value
          end
        else
          if with_session?
            session[name] ||= send("default_#{name}")
          else
            send("default_#{name}")
          end
        end
    end

    def default_locale
      http_accept_language.compatible_language_from(I18n.available_locales)&.to_s
    end

    def default_time_zone
      Time.find_zone(cookies["js.time_zone"])&.name
    end

    def default_currency
      Money.default_currency.to_s
    end
  end
end
