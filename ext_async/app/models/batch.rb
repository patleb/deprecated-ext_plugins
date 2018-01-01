class Batch < ExtAsync.config.parent_model.constantize
  validates :url, url: true, format: { with: /\/_async\// }
  validates :run_at, presence: true

  def self.dequeue
    pk = "#{quoted_table_name}.#{quoted_primary_key}"
    async = "#{quoted_table_name}.async"
    run_at = "#{quoted_table_name}.run_at"
    query = <<-SQL
      DELETE FROM #{quoted_table_name}
      WHERE #{pk} = (
        SELECT #{pk} FROM #{quoted_table_name}
        WHERE #{run_at} <= now()
        ORDER BY #{async} DESC, #{run_at}
        FOR UPDATE SKIP LOCKED
        LIMIT 1
      )
      RETURNING *;
    SQL
    find_by_sql(query).first
  end
end
