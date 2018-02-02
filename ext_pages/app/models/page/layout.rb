class Page::Layout < Page
  has_many :templates, foreign_key: :page_id, dependent: :restrict_with_error

  def layout
    self
  end

  def view
    view_path.sub /^layouts\//, ''
  end
end
