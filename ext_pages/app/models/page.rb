class Page < ExtPages.config.parent_model.constantize
  extend Mobility

  has_many :translations, -> { where(translatable_type: Page.inherited_types) }, as: :translatable, dependent: :destroy
  has_many :contents, dependent: :destroy

  translates :title
  translates :description

  validate :title_slug_exclusion

  before_validation :normalize_attributes

  def default_title
    Rails.application.title
  end

  def default_description
    title || default_title
  end

  private

  def title_slug_exclusion
    if title && ExtPages.config.reserved_words.include?(title.slugify)
      errors.add :title, :exclusion
    end
  end

  def normalize_attributes
    self.title = title.titlefy if title
    self.description = description.squish if description
  end
end
