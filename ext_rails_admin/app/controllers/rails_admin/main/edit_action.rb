module RailsAdmin
  module Main
    module EditAction
      def edit
        if request.get? # EDIT
          respond_to do |format|
            format.html { render @action.template_name }
            format.js   { render @action.template_name, layout: false }
          end
        elsif request.put? # UPDATE
          sanitize_params_for!(params[:modal].to_b ? :modal : :update)

          attributes = params[@abstract_model.param_key]
          @object.set_attributes(attributes)
          @authorization_adapter && @authorization_adapter.attributes_for(:update, @abstract_model).each do |name, value|
            @object.send("#{name}=", value)
          end
          changes = @object.changes
          if @object.save
            @auditing_adapter && @auditing_adapter.update_object(@object, @abstract_model, current_user, changes)
            respond_to do |format|
              format.html { redirect_to_on_success }
              format.js do
                if params[:inline].to_b
                  field_name, _field_value = attributes.to_h.first
                  field = @model_config.list.with(controller: self, object: @object).visible_fields.find do |f|
                    f.inline_update? && f.name == field_name.to_sym
                  end
                  render json: {value: field.value, label: field.pretty_value}
                else
                  render json: {value: @object.id.to_s, label: @model_config.with(controller: self, object: @object).object_label}
                end
              end
            end
          else
            handle_save_error :edit
          end
        end
      end
    end
  end
end
