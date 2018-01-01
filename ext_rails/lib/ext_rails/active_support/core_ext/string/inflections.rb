String.class_eval do
  def dehumanize
    parameterize(separator: '_')
  end
end
