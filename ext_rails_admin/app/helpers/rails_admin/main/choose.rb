module RailsAdmin
  module Main
    class Choose < Base
      delegate :section_name, :section_model_config, to: :controller

      def render
        return unless section_model_config.choose?

        html(
          div('.form-group.control-group') do[
            label_('.col-sm-2.control-label', t('admin.choose.saved'), for: "main_chosen"),
            div('.col-sm-4.controls') do
              select_tag 'main[chosen]', chosen_options, include_blank: true, class: 'form-control js_inline_choose_list'
            end
          ]end,
          # TODO add authorization adapter
          div('.form-group.form-actions') do
            div '.col-sm-offset-2.col-sm-10' do[
              div(class: bs_form_row) do
                text_field_tag 'inline_choose[label]', nil,
                  placeholder: t('admin.choose.label'),
                  class: 'form-control js_inline_choose_label',
                  required: true
              end,
              span('.btn.btn-sm.btn-primary.js_inline_choose_save') do[
                i('.icon-ok'),
                t('admin.form.save')
              ]end,
              span('.btn.btn-sm.btn-default.js_inline_choose_delete') do[
                i('.icon-trash'),
                t("admin.form.delete")
              ]end,
              # TODO set as default --> user preferences
            ]end
          end
        )
      end

      def chosen_options
        options_for_select(chooses.sort_by(&:first).each_with_object({}){ |(key, value), memo|
          memo[key.underscore.humanize] = value.to_json
        }, chosen_default)
      end

      def chosen_default
        params[:main].try(:[], :chosen)
      end

      def chooses
        @_chooses ||= RailsAdmin::Choose.group_by_label(
          section: section_name,
          model: @abstract_model.to_param,
          prefix: section_model_config.choose_prefix
        )
      end
    end
  end
end
