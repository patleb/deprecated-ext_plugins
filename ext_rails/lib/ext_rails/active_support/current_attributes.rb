ActiveSupport::CurrentAttributes.class_eval do
  def self.[](name)
    attributes[name.to_sym]
  end

  def self.[]=(name, value)
    attribute name unless respond_to? name
    attributes[name.to_sym] = value
  end
end
