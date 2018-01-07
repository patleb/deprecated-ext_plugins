module Admin::Setting
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      configure :id do
        pretty_value { value.humanize }
      end

      configure :description do
        sortable false
      end

      edit do
        field :id do
          read_only true
          help false
        end

        field :value, :string

        field :description do
          read_only true
          help false
        end

        field :history do
          pretty_value do
            div do
              m.history.reverse.first(ExtSettings.config.history_show_limit).map do |s|
                p_ "[#{to_local_time s.updated_at}] #{s.value}"
              end
            end
          end
          read_only true
          help false
        end

        field :lock_version, :hidden
      end

      include_fields :id, :value, :description, :updated_at
    end
  end
end
