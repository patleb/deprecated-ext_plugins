Array.class_eval do
  def to_h
    super
  rescue
    map{ |item| [item, item] }.to_h
  end

  def except(*values)
    self - values
  end
end
