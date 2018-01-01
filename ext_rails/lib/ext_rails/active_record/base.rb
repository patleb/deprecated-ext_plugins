ActiveRecord::Base.class_eval do
  delegate :url_helpers, to: 'Rails.application.routes'

  def self.sanitize_matcher(regex)
    like = sanitize_sql_like(regex.to_string)
    like.gsub!('.*', '%')
    like.gsub!('.', '_')
    like = (like.start_with? '^') ? like[1..-1] : "%#{like}"
    (like.end_with? '$') ? like.chop! : (like << '%')
  end

  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      ([:restrict_with_error, :restrict_with_exception].exclude? assoc.options[:dependent]) ||
        (assoc.macro == :has_one && self.send(assoc.name).nil?) ||
        (assoc.macro == :has_many && self.send(assoc.name).empty?)
    end
  end
end
