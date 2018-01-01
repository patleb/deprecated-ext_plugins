# TODO allow set each type of argument and generate them as input on the fly

module Admin::Task
  extend ActiveSupport::Concern

  included do
    rails_admin do
      configure :id do
        pretty_value{ value.sub(/^ext_(rake)?/, '').tr(':', '_').humanize }
      end

      list do
        configure :id do
          queryable true
          searchable true
        end
        configure :output do
          pretty_value{ simple_format(truncate(value, length: ExtTasks.config.output_length)) }
        end
        configure :status, :boolean
      end

      edit do
        configure :id do
          read_only true
          help false
        end
        configure :output do
          pretty_value{ simple_format(value) }
          read_only true
          help false
        end
        configure :parameters do
          read_only true
          help false
        end
        configure :arguments do
          visible{ m.parameters.present? }
        end
        configure :_later, :hidden do
          default_value{ true }
        end

        include_all_fields
      end
    end
  end
end
