class Global < ExtGlobals.config.parent_model.constantize
  include Store

  self.inheritance_column = nil

  enum type: {
    text:       0,
    texts:      1,
    json:       2,
    jsons:      3,
    boolean:    4,
    booleans:   5,
    integer:    6,
    integers:   7,
    decimal:    8,
    decimals:   9,
    datetime:   10,
    datetimes:  11,
    interval:   12,
    intervals:  13,
  }

  attribute :data

  after_initialize :set_data

  def self.fetch_record(name, force: false, expires: false, **_options)
    # TODO respond_to? :global_key
    begin
      if force || (record = where(id: name).take).nil?
        if block_given?
          default = yield(name)
          type = type_of default
          record = create! id: name, type: type, expires: expires, data: default
          record.new!
        else
          raise ArgumentError, "Missing block: Calling `Global#fetch_record` requires a block."
        end
      end
    rescue ActiveRecord::RecordNotUnique
      record = where(id: name).take!
    end

    touch(record)
  end

  def self.[](*names)
    if names.size == 1
      name = names.first
      if name.is_a? Regexp
        name = sanitize_matcher(name)
        where.has{ id =~ name }.each_with_object({}) do |record, memo|
          memo[record.id] = touch(record).data
        end
      elsif (record = where(id: name).take)
        touch(record).data
      end
    else
      where(id: names).each_with_object({}) do |record, memo|
        memo[record.id] = touch(record).data
      end
    end
  end

  def new?
    @_new
  end

  def new!
    @_new = true
  end

  def data=(data)
    if (new_type = self.class.type_of(data)) != type
      self[type] = nil
      self.type = new_type
    end
    self[:data] = self[type] = cast(data)
  end

  private_class_method

  def self.type_of(data)
    case data
    when Array
      type_of(data.first).pluralize
    when Hash                    then 'json'
    when Boolean                 then 'boolean'
    when Integer                 then 'integer'
    when Float, BigDecimal       then 'decimal'
    when Date, Time, DateTime    then 'datetime'
    when ActiveSupport::Duration then 'interval'
    else
      'text'
    end
  end

  def self.touch(record)
    if record.expires? && record.updated_at < ExtGlobals.config.touch_in.ago
      record.touch
    end
    record
  end

  private

  def set_data
    self[:data] = cast(self[type])
    clear_attribute_changes [:data]
  end

  def cast(data)
    return data unless data

    if type.start_with? 'json'
      if type.end_with? 's'
        data.map!(&:with_indifferent_access)
      else
        data.with_indifferent_access
      end
    else
      data
    end
  end
end
