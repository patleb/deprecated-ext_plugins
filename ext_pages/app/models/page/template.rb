class Page::Template < Page
  include Page::AsView

  belongs_to :layout, foreign_key: :page_id, class_name: Page::Layout.name
  has_many   :pages, dependent: :restrict_with_error

  validates :layout, presence: true

  def self.fetch_or_create_by_view_path!(view_path)
    eager_load(:layout, :translations).find_or_create_by! view_path: view_path do |page|
      page.version = ExtRails.config.version
      yield page
    end
  end

  def with_associations
    self.class.eager_load(:layout, :translations).where(id: id).take!
  end

  def template
    self
  end
end
