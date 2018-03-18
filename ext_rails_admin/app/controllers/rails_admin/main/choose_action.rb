module RailsAdmin
  module Main
    module ChooseAction
      def choose
        attributes = params.require(:main).permit(:section, :label, chosen: [:value, :label], fields: [:field, :calculation])
        attributes.merge!(model: @abstract_model.to_param, prefix: section_model_config(attributes[:section]).choose_prefix)
        notice_name = I18n.t('admin.choose.view')

        if request.post? # CREATE or UPDATE
          @object = RailsAdmin::Choose.new(attributes)
          if @object.save
            redirect_to_on_success notice_name
          else
            handle_save_error :main, notice_name
          end
        elsif request.delete? # DESTROY
          attributes = attributes.slice!(:section, :model, :prefix, :label).to_unsafe_h.symbolize_keys
          if RailsAdmin::Choose.exist? attributes
            RailsAdmin::Choose.delete_by(attributes)
            redirect_to_on_success notice_name, status: :see_other
          else
            redirect_to(back_or_index, notice: I18n.t('admin.flash.noaction'), status: :see_other)
          end
        end
      end

      def section_model_config(section = section_name)
        @_section_model_config ||= @model_config.send(section).with(controller: self)
      end

      def section_name
        action_name == 'index' ? 'list' : action_name
      end
    end
  end
end
