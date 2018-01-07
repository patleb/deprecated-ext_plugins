module Admin::Batch
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      show do
        configure :url do
          pretty_value do
            path, params = value.split('?')
            div do[
              pre { path },
              pre { JSON.pretty_generate(Rack::Utils.parse_nested_query(params)) if params }
            ]end
          end
        end
      end

      list do
        configure :url do
          skipped = /(request|session|job|batch|currency|locale|time_zone|user)/
          pretty_value{ value.sub(/^https?:\/\/.+\//, '/').gsub(/_#{skipped}(_(id|timestamp))?=[\%\w-]+&/, '') }
        end

        exclude_fields :updated_at
      end
    end
  end
end
