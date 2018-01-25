class Page < ExtPages.config.parent_model.constantize
  has_many :translations, -> { where(translatable_type: Page.inheritance_types) }, foreign_key: :translatable_id
  has_many :contents, dependent: :destroy
end
