module RailsAdmin
  module Main
    module NewAction
      def new
        if request.get? # NEW
          @object = @abstract_model.new
          @authorization_adapter && @authorization_adapter.attributes_for(:new, @abstract_model).each do |name, value|
            @object.send("#{name}=", value)
          end
          if object_params = params[@abstract_model.param_key]
            sanitize_params_for!(params[:modal].to_b ? :modal : :create)
            @object.set_attributes(@object.attributes.merge(object_params.to_h))
          end
          respond_to do |format|
            format.html { render @action.template_name }
            format.js   { render @action.template_name, layout: false }
          end
        elsif request.post? # CREATE
          @modified_assoc = []
          @object = @abstract_model.new
          sanitize_params_for!(params[:modal].to_b ? :modal : :create)

          @object.set_attributes(params[@abstract_model.param_key])
          @authorization_adapter && @authorization_adapter.attributes_for(:create, @abstract_model).each do |name, value|
            @object.send("#{name}=", value)
          end

          if @object.save
            @auditing_adapter && @auditing_adapter.create_object(@object, @abstract_model, current_user)
            respond_to do |format|
              format.html { redirect_to_on_success }
              format.js do
                if params[:inline].to_b
                  flash.now[:success] = I18n.t('admin.flash.successful', name: @model_config.label, action: I18n.t("admin.actions.#{@action.key}.done"))
                end
                render json: {value: @object.id.to_s, label: @model_config.with(controller: self, object: @object).object_label}
              end
            end
          else
            handle_save_error :new
          end
        end
      end
    end
  end
end
