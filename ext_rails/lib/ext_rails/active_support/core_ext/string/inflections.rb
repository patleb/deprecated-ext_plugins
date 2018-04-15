String.class_eval do
  def dehumanize
    parameterize(separator: '_')
  end

  def slugify
    parameterize.dasherize.downcase
  end

  def titlefy
    parameterize.humanize.squish.gsub(/([[:word:]]+)/u){ |word| word.downcase.capitalize }
  end
end
