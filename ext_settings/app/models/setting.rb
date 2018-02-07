class Setting < ExtSettings.config.parent_model.constantize
  include SettingsYml::Type

  has_logidze

  class Entry < OpenStruct
  end

  def self.yml
    SettingsYml
  end

  scope :visible, -> { where(id: ExtSettings.config.settings_visible) }
  scope :hidden, -> { where.not(id: ExtSettings.config.settings_visible) }

  def self.[](name)
    if (value = SettingsYml[name])
      value
    else
      record = where(id: name).select(:id, :value).take!
      cast(record.value, SettingsYml.type_of(record.id))
    end
  end

  def self.has_key?(name)
    if SettingsYml[name]
      true
    elsif where(id: name).exists?
      true
    else
      false
    end
  end
  singleton_class.send :alias_method, :key?, :has_key?

  def self.rename(old_name, new_name)
    find(old_name).update!(id: new_name)
  end

  def self.modify(name, value)
    find(name).update!(value: value)
  end

  def self.find_or_create_all(**settings)
    reverse = settings.delete(:reverse)
    settings.send(reverse ? :reverse_each : :each) do |name, value|
      find_or_create_by!(id: name) do |setting|
        if value.is_a? Array
          setting.value, setting.description = value
        else
          setting.value = value
        end
      end
    end
  end

  def self.modify_all(**settings)
    where(id: settings.keys).each do |setting|
      if (value = settings[setting.id.to_sym]).is_a? Array
        setting.update! value: value[0], description: value[1]
      else
        setting.update! value: value
      end
    end
  end

  def self.remove_all(*settings)
    where(id: settings).destroy_all
  end

  def history
    @history ||= log_data.data['h'].map{ |h| Entry.new(h['c'].slice('value', 'updated_at')) }
  end
end
