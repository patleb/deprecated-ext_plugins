class RailsAdmin.FieldConcept::SelectMultiRemoteElement extends RailsAdmin.FieldConcept::SelectMultiElement
  constructor: (@input) ->
    super
    @super_2('constructor', @input)

  render: =>
    @render_list()
    @update_list(@control.val())
    @show_field()

  update_on_keydown: (event) =>
    @super_2('update_on_keydown', event)

  update_on_keyup: (event) =>
    @super_2('update_on_keyup', event)

  close: =>
    @placeholder.removeClass(@HIDE_CLASS)
    @super_2('close')

  #### PRIVATE ####

  set_control: _.noop

  show_field: =>
    @control.addClass(@SHOW_CLASS)
    @input.addClass(@HIDE_CLASS)
    @keep_focus = true
    @control.click().focus().cursor_end(true)
    @placeholder.addClass(@HIDE_CLASS).hide()
    setTimeout =>
      @placeholder.show()
      @keep_focus = false
