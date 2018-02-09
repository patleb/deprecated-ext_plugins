module Admin::User
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      object_label_method do
        :email
      end

      edit do
        field :email do
          required true
        end
        field :password do
          required true
        end
      end

      list do
        sort_by :updated_at
        fields :email, :updated_at, :created_at
      end
    end
  end
end
