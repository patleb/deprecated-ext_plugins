Regexp.class_eval do
  def to_string
    to_s.sub(/^\(\?-mix:/, '').sub(/\)$/, '')
  end
end
