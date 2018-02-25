require "ext_throttler/engine"

module ExtThrottler
  PREFIX = 'ext_throttler'.freeze

  def self.status(key:, value:, duration: nil)
    key = [PREFIX, key].join(':')
    new_value =
      case value
      when Symbol
        value.to_s
      when String, Array, Hash
        value
      else
        value.class.to_s
      end
    new_time = Time.current.utc

    record = Global.fetch_record(key) do
      { value: new_value, time: new_time.iso8601, count: 1 }
    end

    if record.new?
      return { throttled: false }
    end

    record.with_lock do
      old_value, old_time, count = record.data.values

      count = count.to_i + 1
      if new_value != old_value
        return update(record, old_value, new_value, new_time, count)
      end

      elapsed_time = (new_time - Time.zone.parse(old_time)).to_i.seconds
      if elapsed_time >= (duration || ExtThrottler.config.duration)
        return update(record, old_value, old_value, new_time, count)
      end

      # TODO count limit
      # https://github.com/zendesk/prop
      # https://github.com/fredwu/action_throttler

      if block_given? && yield(old_time, count)
        return update(record, old_value, old_value, new_time, count)
      end

      update(record, old_value, old_value, old_time, count, throttled: true)
    end
  rescue ActiveRecord::RecordNotFound
    retry
  end
  
  private_class_method
  
  def self.update(record, old_value, new_value, time, count, throttled: false)
    record.update! data: { value: new_value, time: time.iso8601, count: throttled ? count : 1 }

    { throttled: throttled, previous: old_value, count: count }
  end
end
