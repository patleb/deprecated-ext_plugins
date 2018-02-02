module Page::WithCache
  extend ActiveSupport::Concern

  included do
    translates :html_cache, backend: :column, cache: false

    jsonb_accessor :data,
      version: :string

    validates :version, presence: true

    before_create :set_version
  end

  def html_cache_expired?
    return true if ExtRails.config.version != version
    return true unless html_cache

    [self, template, layout].map(&:updated_at).max > html_cache_record.updated_at
  end

  def update_html_cache!(body)
    self.html_cache = body
    return unless html_cache_changed?

    current_updated_at = updated_at
    save!
    update_columns updated_at: current_updated_at
  end

  private

  def set_version
    self.version ||= ExtRails.config.version
  end

  def html_cache_record
    @_html_cache_record ||= translations.find{ |t| t.locale == Current.locale && t.key == 'html_cache' }
  end
end
