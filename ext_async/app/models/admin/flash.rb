module Admin::Flash
  extend ActiveSupport::Concern

  included do
    rails_admin do
      list do
        configure :messages do
          pretty_value{ value.first.last }
        end
      end
    end
  end
end
