Mobility.configure do |config|
  default_locale = Rails.application.config.i18n.default_locale
  other_locales = Rails.application.config.i18n.available_locales.except(default_locale)

  config.default_backend = :key_value
  config.accessor_method = :translates
  config.query_method    = :i18n
  config.default_options[:association_name] = :translations
  config.default_options[:class_name] = 'Translation'
  config.default_options[:attribute_methods] = true
  config.default_options[:dirty] = true
  config.default_options[:locale_accessors] = true
  config.default_options[:fallbacks] = other_locales.each_with_object({}) do |locale, memo|
    memo[locale] = default_locale
  end
end
