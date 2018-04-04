module Global::Store
  extend ActiveSupport::Concern

  class_methods do
    def exist?(name, _options = nil)
      exists?(name)
    end

    def fetch(name, force: false, expires: false, **_options)
      if block_given?
        fetch_record(name, force: force, expires: expires){ yield(name) }.data
      else
        read(name)
      end
    end

    def fetch_multi(*names, expires: false)
      raise ArgumentError, "Missing block: Calling `Global#fetch_multi` requires a block." unless block_given?

      results = read_multi(*names)
      (names - results.keys).each do |name|
        record = fetch_record(name, force: true, expires: expires){ yield(name) }
        results[record.id] = record.data
      end
      results
    end

    def read(name, _options = nil)
      self[name]
    end

    def read_multi(*names)
      self[*names]
    end

    def write(name, value, lock: false, expires: false, **_options)
      record = fetch_record(name, expires: expires){ value }
      unless record.new?
        record.with_lock(lock) do
          record.update! data: value
        end
      end
      value
    rescue ActiveRecord::RecordNotFound
      retry
    end

    def increment(name, amount = 1, _options = nil)
      update_integer(name, amount)
    end

    def decrement(name, amount = 1, _options = nil)
      update_integer(name, -amount)
    end

    def delete(name, lock: false, **_options)
      where(id: name).lock(lock).delete_all
    end

    def delete_matched(matcher, lock: false, **_options)
      raise ArgumentError, "Bad type: `Global#delete_matched` requires a Regexp." unless matcher.is_a? Regexp

      matcher = sanitize_matcher(matcher)
      matched = where.has{ id =~ matcher }
      if lock
        # TODO quite slow, might want to move this to a stored procedure
        matched.find_each{ |record| delete(record.id, lock: lock) }
      else
        matched.delete_all
      end
    end

    def cleanup(lock: false, **_options)
      expires_at = ExtGlobals.config.expires_in.ago
      expired = where(expires: true).where.has{ updated_at < expires_at }
      if lock
        expired.find_each{ |record| delete(record.id, lock: lock) }
      else
        expired.delete_all
      end
    end

    def clear(lock: false, **_options)
      expirables = where(expires: true)
      if lock
        expirables.find_each{ |record| delete(record.id, lock: lock) }
      else
        expirables.delete_all
      end
    end

    def clear!
      with_table_lock do
        connection.execute("TRUNCATE TABLE #{quoted_table_name}")
      end
    end

    private

    def update_integer(name, amount)
      if update_counters(name, integer: amount, touch: true) == 0
        create! id: name, type: :integer, integer: amount
      end
      1
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
