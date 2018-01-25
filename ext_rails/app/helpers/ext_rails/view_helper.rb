module ExtRails
  module ViewHelper
    def current_layout
      @_current_layout ||= (self.is_a?(ActionController::Base) ? self : controller).send(:_layout, []) || 'application'
    end

    def application_name
      Rails.application.title
    end

    def body_id
      current_layout.split('/').first
    end

    def query_diet(**options)
      query_diet_widget(options) if Rails.env.development?
    end

    def locale_select
      case I18n.available_locales.size
      when 1
        ''
      when 2
        locale = I18n.available_locales.find{ |l| I18n.locale != l }
        link_to locale.to_s.camelize, "?_locale=#{locale}", class: 'locale_select'
      else
        div '.locale_select' do
          locales = [[I18n.locale.to_s.camelize, ""]] + I18n.available_locales.reject{ |l| I18n.locale == l }.map do |l|
            [l.to_s.camelize, "?_locale=#{l}"]
          end
          select_tag :locales, options_for_select(locales), onchange: "if(this.value){location = this.value}"
        end
      end
    end
  end
end
