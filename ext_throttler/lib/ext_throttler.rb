require "ext_throttler/engine"

module ExtThrottler
  PREFIX = 'ext_throttler'.freeze

  def self.status(key:, value:, duration: nil)
    key = [PREFIX, key].join(':')
    new_value =
      case value
      when String, Symbol
        value.to_s
      else
        value.class.to_s
      end
    now = Time.current.utc

    record = Global.fetch_record(key) do
      { value: new_value, time: now.iso8601, count: 1 }
    end

    if record.new?
      return { throttled: false }
    end

    record.with_lock do
      old_value, time, count = record.data.values

      count = count.to_i + 1
      if new_value != old_value
        record.update! data: { value: new_value, time: now.iso8601, count: 1 }
        return { throttled: false, previous: old_value, count: count }
      end

      elapsed_time = (now - Time.zone.parse(time)).to_i.seconds
      if elapsed_time >= (duration || ExtThrottler.config.duration)
        record.update! data: { value: old_value, time: now.iso8601, count: 1 }
        return { throttled: false, previous: old_value, count: count }
      end

      record.update! data: { value: old_value, time: time, count: count }
      { throttled: true, previous: old_value, count: count }
    end
  rescue ActiveRecord::RecordNotFound
    retry
  end
end
