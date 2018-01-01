module Admin::Batch
  extend ActiveSupport::Concern

  included do
    rails_admin do
      list do
        configure :url do
          pretty_value{ value.sub(/^https?:\/\/.+\//, '/').gsub(/_(job|batch)_id=[\w-]+&/, '') }
        end

        exclude_fields :updated_at
      end
    end
  end
end
