class Content < ExtPages.config.parent_model.constantize
  extend Mobility

  acts_as_list scope: [:page_id, :name]

  has_many   :translations, -> { where(translatable_type: Content.inherited_types) }, as: :translatable, dependent: :destroy
  belongs_to :page, touch: true

  delegate :view_path, :layout, to: :page
end
