module Boolean; end

String.class_eval do
  def to_b
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: '#{self}'")
  end

  def to_b?
    self == true || self =~ (/^(true|t|yes|y|1)$/i) || self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
  end
end

Numeric.class_eval do
  def to_b
    return true if self == 1
    return false if self == 0
    raise ArgumentError.new("invalid value for Boolean: '#{self}'")
  end

  def to_b?
    self == 1 || self == 0
  end
end

TrueClass.class_eval do
  include Boolean
  def to_f; 1.0; end
  def to_i; 1; end
  def to_b; self; end
  def to_b?; true; end
end

FalseClass.class_eval do
  include Boolean
  def to_f; 0.0; end
  def to_i; 0; end
  def to_b; self; end
  def to_b?; true; end
end

NilClass.class_eval do
  def to_b; false; end
  def to_b?; true; end
end
