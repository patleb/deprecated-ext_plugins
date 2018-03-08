Array.class_eval do
  def to_h
    super
  rescue
    map{ |item| [item, item] }.to_h
  end

  def to_range
    Range.new(first, last)
  end

  def except(*values)
    self - values
  end

  def insert_after(anchor, value)
    insert((index(anchor) || -1) + 1, value)
  end
end
