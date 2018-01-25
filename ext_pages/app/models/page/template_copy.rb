class Page::TemplateCopy < Page
  include Page::AsView

  belongs_to :template, foreign_key: :page_id, class_name: Page::Template.name
  has_one    :layout, through: :template

  delegate :view_path, to: :template

  def with_associations
    self.class.eager_load({ template: [:layout, :translations] }, :translations).where(id: id).take!
  end

  def default_title
    template.title
  end
end
