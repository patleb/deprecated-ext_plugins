module RailsAdmin
  class Choose < ActiveType::Object
    attribute :section
    attribute :model
    attribute :prefix
    attribute :label
    attribute :chosen, :hash
    attribute :fields, :array

    with_options presence: true do
      validates :section
      validates :model
      validates :label
      validates :fields
    end

    before_save :save_now

    def self.global_key(section, model, prefix, label)
      ['rails_admin:choose', section, model, prefix, label.parameterize].compact.join(':')
    end

    def self.delete_by(section:, model:, prefix:, label:)
      Global.delete(global_key(section, model, prefix, label))
    end

    def self.group_by_label(section:, model:, prefix:)
      Global.read_multi(/^#{global_key(section, model, prefix, '')}/).transform_keys! do |key|
        key.match(/:([^:]+)$/)[1]
      end
    end

    def save_now
      if chosen_label.present?
        old_key = self.class.global_key(section, model, prefix, chosen_label)
        if (old_record = Global.where(id: old_key).take)
          if fields == old_record.data
            old_record.delete
          end
        end
      end

      return if (record = Global.fetch_record(global_key){ fields }).new?

      record.with_lock do
        record.update! data: fields
      end
    rescue ActiveRecord::RecordNotFound
      retry
    end

    def chosen_label
      chosen.try(:[], :label)
    end

    def global_key
      self.class.global_key(section, model, prefix, label)
    end
  end
end
