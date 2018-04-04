ActiveRecord::Base.class_eval do
  self.store_base_sti_class = false

  delegate :url_helpers, to: 'Rails.application.routes'

  def self.self_and_inherited_types
    @self_and_inherited_types ||= [base_class.name].concat inherited_types
  end

  def self.inherited_types
    @inherited_types ||= base_class.descendants.map(&:name)
  end

  def self.sanitize_matcher(regex)
    like = sanitize_sql_like(regex.to_string).gsub "\\/", '/'
    like.gsub!('.*', '%')
    like.gsub!('.', '_')
    like = (like.start_with? '^') ? like[1..-1] : "%#{like}"
    (like.end_with? '$') ? like.chop! : (like << '%')
  end

  def self.quoted_column(name)
    table, column = name.to_s.split('.', 2)
    if column
      [connection.quote_table_name(table), connection.quote_column_name(column)].join('.')
    else
      connection.quote_column_name(table)
    end
  end

  def self.quoted_columns(*names)
    names.map{ |name| quoted_column(name) }
  end

  def self.total_size
    result = connection.execute(<<~SQL)
      SELECT pg_database.datname AS "name", pg_size_pretty(pg_database_size(pg_database.datname)) AS "size"
      FROM pg_database;
    SQL
    result.find{ |entry| entry['name'] == connection_config[:database] }['size']
  end

  def self.size
    sizes[table_name]
  end

  def self.sizes
    result = connection.execute(<<~SQL)
      SELECT relname AS "name", pg_size_pretty(pg_total_relation_size(relid)) AS "size" 
      FROM pg_catalog.pg_statio_user_tables
      ORDER BY pg_total_relation_size(relid) DESC;
    SQL
    result.each_with_object({}.with_indifferent_access) do |entry, memo|
      memo[entry['name']] = entry['size']
    end
  end

  def locking_enabled?
    super && changed.any? { |attribute| ExtRails.config.skip_locking.exclude? attribute }
  end

  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      ([:restrict_with_error, :restrict_with_exception].exclude? assoc.options[:dependent]) ||
        (assoc.macro == :has_one && self.send(assoc.name).nil?) ||
        (assoc.macro == :has_many && self.send(assoc.name).empty?)
    end
  end
end
