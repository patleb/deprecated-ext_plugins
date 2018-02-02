class Page::Template < Page
  belongs_to :layout, foreign_key: :page_id
  has_many   :pages, foreign_key: :page_id
  has_one    :page, -> { order(:level_parent_id, :level_slot) }, foreign_key: :page_id

  validates :layout, presence: true

  def nuke!
    pages.each(&:nuke!)
    destroy!
  end

  def self.fetch_page_by_view_path!(view_path)
    template = eager_load(:layout, :page).where(view_path: view_path).take!
    page = template.page
    page.template = template
    page
  end

  def template
    self
  end

  def view
    view_path.sub /^pages\//, ''
  end

  def default_title
    view.parameterize.titleize
  end
end
