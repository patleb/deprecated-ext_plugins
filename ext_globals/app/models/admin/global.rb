module Admin::Global
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      configure :id do
        read_only true
        help false
      end

      configure :data do
        pretty_value{ simple_format(truncate(m.data.to_s, length: ExtGlobals.config.output_length)) }
      end

      configure :type do
        read_only true
        help false
      end

      show do
        exclude_fields :type, :data
      end

      list do
        # TODO bug cannot sort_reverse id
        sort_by :updated_at
        include_fields :id, :expires, :type, :data, :updated_at
      end

      edit do
        field :id
        field :expires
        included_types = Global.types.keys.reject!{ |type| type.end_with?('s') }
        included_types.each do |type|
          field type, type do
            visible do
              m.type == type
            end
          end
        end
      end
    end
  end
end
