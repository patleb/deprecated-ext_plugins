module Page::WithLevel
  extend ActiveSupport::Concern

  included do
    acts_as_list column: :level_slot, scope: :level_parent_id

    belongs_to :level_parent, foreign_key: :level_parent_id
  end

  class_methods do

  end

end
