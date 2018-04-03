module Admin::Server::Global
  extend ActiveSupport::Concern

  included do
    include Admin::Global

    rails_admin do
      navigation_label I18n.t('admin.navigation.server')
      weight 950
    end
  end
end
