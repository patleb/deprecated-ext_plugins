module Admin::Flash
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      list do
        configure :messages do
          pretty_value{ value.first.last }
        end
      end
    end
  end
end
