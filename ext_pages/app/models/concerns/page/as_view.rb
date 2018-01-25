module Page::AsView
  extend ActiveSupport::Concern

  URL_SEGMENT = 'p'.freeze

  included do
    extend Mobility
    include Page::WithCache
    include Page::WithContent

    translates :title, default: -> { default_title }
    translates :description, default: -> { title }

    jsonb_accessor :data,
      published_at: :datetime

    validates :title, presence: true
    validate :title_slug_exclusion

    before_validation :normalize_attributes

    define_method :to_param do
      [title.slugify, URL_SEGMENT, hashid].join('/')
    end
  end

  def view
    view_path.sub /^pages\//, ''
  end

  def publish!
    update! published_at: Time.current.utc
  end

  def default_title
    template.view.parameterize.titleize
  end

  private

  def title_slug_exclusion
    if ExtPages.config.reserved_words.include? title.slugify
      errors.add :title, :exclusion
    end
  end

  def normalize_attributes
    self.title = title.squish.titlefy if title
  end
end
