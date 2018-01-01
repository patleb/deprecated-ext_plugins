module RailsAdmin
  module Config
    module Fields
      module Types
        class PolymorphicAssociation < RailsAdmin::Config::Fields::Types::BelongsToAssociation
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :render do
            type_collection = polymorphic_type_collection
            type_column = association.foreign_type.to_s
            selected_type = bindings[:object].send(type_column)
            collection = associated_collection(selected_type)
            selected = bindings[:object].send(association.name)
            column_type_dom_id = form.dom_id(field).sub(method_name.to_s, type_column)
            div '.form-inline' do[
              form.select(type_column, type_collection, {include_blank: true, selected: selected_type}, class: "form-control", id: column_type_dom_id, data: { polymorphic: true, urls: polymorphic_type_urls.to_json }),
              form.select(method_name, collection, {include_blank: true, selected: selected.try(:id)}, class: "form-control")
            ]end
          end

          # Accessor whether association is visible or not. By default
          # association checks that any of the child models are included in
          # configuration.
          register_instance_option :visible? do
            associated_model_config.any?
          end

          register_instance_option :formatted_value do
            (o = value) && o.send(RailsAdmin.config(o).object_label_method)
          end

          register_instance_option :sortable do
            false
          end

          register_instance_option :searchable do
            false
          end

          # TODO: not supported yet
          register_instance_option :associated_collection_cache_all do
            false
          end

          # TODO: not supported yet
          register_instance_option :associated_collection_scope do
            nil
          end

          register_instance_option :allowed_methods do
            [children_fields]
          end

          register_instance_option :eager_load? do
            false
          end

          def associated_collection(type)
            return [] if type.blank?
            config = RailsAdmin.config(type)
            config.abstract_model.all.collect do |object|
              [object.send(config.object_label_method), object.id]
            end
          end

          def associated_model_config
            @associated_model_config ||= association.klass.collect { |type| RailsAdmin.config(type) }.select { |config| !config.excluded? }
          end

          def polymorphic_type_collection
            associated_model_config.collect do |config|
              [config.label, config.abstract_model.model.name]
            end
          end

          def polymorphic_type_urls
            types = associated_model_config.collect do |config|
              [config.abstract_model.model.name, config.abstract_model.to_param]
            end
            ::Hash[*types.collect { |v| [v[0], bindings[:view].index_path(v[1])] }.flatten]
          end

          # Reader for field's value
          def value
            bindings[:object].send(association.name)
          end
        end
      end
    end
  end
end
