require "unicode"

String.class_eval do
  def downcase
    Unicode::downcase(self)
  end

  def upcase
    Unicode::upcase(self)
  end

  def capitalize
    Unicode::capitalize(self)
  end

  def escape_regex
    Regexp.new(Regexp.escape(self)).to_string
  end

  def escape_single_quotes
    gsub(/'/, '\\x27')
  end

  def escape_newlines
    gsub(/\r?\n/, "\\\\n")
  end

  def unescape_newlines
    gsub(/\\n/, "\n")
  end

  %i(
    downcase
    upcase
    capitalize
    escape_single_quotes
    escape_newlines
    unescape_newlines
  ).each do |name|
    define_method :"#{name}!" do
      self.replace send(name)
    end
  end
end
