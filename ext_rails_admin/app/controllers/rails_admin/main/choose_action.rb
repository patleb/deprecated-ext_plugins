module RailsAdmin
  module Main
    module ChooseAction
      def choose
        attributes = params.require(:main).permit(:section, :label, chosen: [:value, :label], fields: [:field, :calculation])
        attributes.merge!(model: @abstract_model.to_param)
        notice_name = I18n.t('admin.choose.view')

        if request.post? # CREATE or UPDATE
          @object = RailsAdmin::Choose.new(attributes)
          if @object.save
            redirect_to_on_success notice_name
          else
            handle_save_error :main, notice_name
          end
        elsif request.delete? # DESTROY
          attributes = attributes.slice!(:section, :model, :label).to_unsafe_h.symbolize_keys
          RailsAdmin::Choose.delete_by(attributes)

          redirect_to_on_success notice_name, status: :see_other
        end
      end
    end
  end
end
