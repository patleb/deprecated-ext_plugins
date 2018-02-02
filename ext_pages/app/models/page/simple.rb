class Page::Simple < Page
  URL_SEGMENT = 'p'.freeze

  #include Page::WithCache
  include Page::WithContent

  belongs_to :template, foreign_key: :page_id

  delegate :layout, :view, :view_path, to: :template

  before_destroy :validate_destroy

  def self.fetch_page_by_hashid!(hashid)
    eager_load(template: :layout).where(id: decode_id(hashid)).take!
  end

  def to_param
    [title.slugify, URL_SEGMENT, hashid].join('/')
  end

  def default_title
    template.title || template.default_title
  end

  def publish!
    update! published_at: Time.current.utc
  end

  def nuke!
    @nuke = true
    destroy!
  end

  def can_destroy?
    super && (@nuke || template.pages.size > 1)
  end

  private

  def validate_destroy
    throw :abort unless can_destroy?
  end
end
