class Rendering < ExtPages.config.parent_model.constantize
  belongs_to :renderable, polymorphic: true

  def html_text
    read_attribute "html_text_#{Current.locale}"
  end

  def html_text=(value)
    write_attribute "html_text_#{Current.locale}", value
  end
end
