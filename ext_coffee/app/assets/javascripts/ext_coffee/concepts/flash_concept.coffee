class Js.FlashConcept
  global: true

  constants: ->
    MESSAGES: 'ID'
    WRAPPER: 'CLASS'

  ready: =>
    return unless (messages = $(@MESSAGES)).length

    @clear()
    messages.data('js').each ([type, message]) =>
      @render(type, message, false)
    messages.data(js: [])
    @auto_dismiss()

  render: (type, message, clear = true) =>
    @clear() if clear
    $(Js.Pjax.CONTAINER).prepend(
      div @WRAPPER, class: "alert alert-dismissible #{@alert_class(type)}", -> [
        button '×', type: 'button', class: 'close', data: { dismiss: 'alert' }
        message.html_safe(true)
      ]
    )

  clear: =>
    $(@WRAPPER).remove()

  #### PRIVATE ####

  alert_class: (type) ->
    switch type
      when 'error'  then 'alert-danger'
      when 'alert'  then 'alert-warning'
      when 'notice' then 'alert-info'
      else "alert-#{type}"

  auto_dismiss: =>
    $('.alert-info:visible, .alert-success:visible').fadeTo(2000, 500).slideUp(500)
