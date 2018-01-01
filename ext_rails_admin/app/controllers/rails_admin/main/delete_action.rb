module RailsAdmin
  module Main
    module DeleteAction
      def delete
        if request.get? # DELETE
          respond_to do |format|
            format.html { render @action.template_name }
            format.js   { render @action.template_name, layout: false }
          end
        elsif request.delete? # DESTROY
          @auditing_adapter && @auditing_adapter.delete_object(@object, @abstract_model, current_user)
          if @object.destroy
            flash[:success] = t('admin.flash.successful', name: @model_config.label, action: t('admin.actions.delete.done'))
            redirect_path = index_path
          else
            flash[:error] = t('admin.flash.error', name: @model_config.label, action: t('admin.actions.delete.done'))
            redirect_path = back_or_index
          end

          redirect_to redirect_path
        end
      end
    end
  end
end
