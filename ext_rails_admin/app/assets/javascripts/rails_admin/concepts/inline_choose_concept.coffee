class RailsAdmin.InlineChooseConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    LIST: 'CLASS'
    LABEL: 'CLASS'
    SAVE: 'CLASS'
    DELETE: 'CLASS'

  document_on: => [
    'click', @SAVE, (event, target) =>
      @submit(target, 'POST')

    'click', @DELETE, (event, target) =>
      @submit(target, 'DELETE', I18n.t('confirmation'))

    'change', @LIST, (event, target) =>
      RailsAdmin[@view_concept].render_list(target.val())
  ]

  ready: =>
    return unless (@list = $(@LIST)).length

    # TODO use inheritance for each type
    @section = if $('#chart_action').length then 'chart' else 'list'
    @view_concept = "#{@section.camelize()}Concept"

  clear: =>
    $(@LIST).clear_value()

  submit: (button, method, confirm_message = null) =>
    return if button.has_once()
    return unless (label = $(@LABEL)).valid()
    return unless confirm(confirm_message) if confirm_message

    chosen = $(@LIST).find(':selected')[0]
    form = $.form_for(
      main:
        section: @section
        label: label.val()
        chosen:
          value: chosen.value
          label: chosen.text
        fields: @current_fields()
      return_to: RailsAdmin.FilterBoxConcept.merge_params(url: window.location.href)
    )
    url = Routes.url_for('choose', model_name: @abstract_model(), inline: true)
    $.pjax(
      url: url
      method: method
      data: JSON.stringify(form)
      contentType: 'application/json'
      push: false
      once: button
      content_error: label
      error: (xhr, status, error) ->
        Flash.error(xhr.responseJSON.flash.error)
    )

  current_fields: =>
    RailsAdmin[@view_concept].current_fields()
