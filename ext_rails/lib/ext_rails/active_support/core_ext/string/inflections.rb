String.class_eval do
  def dehumanize
    parameterize(separator: '_')
  end

  def slugify
    parameterize.downcase
  end

  def titlefy
    dasherize.gsub(/([[:word:]]+)/u){ |word| word.downcase.capitalize }
  end
end
