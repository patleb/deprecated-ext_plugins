# TODO reset
# TODO max children
# TODO list hard delete like the delete view

class RailsAdmin.NestedFormConcept
  constants: ->
    WRAPPER: 'CLASS'
    TOGGLE: 'CLASS'
    ADD: 'CLASS'
    REMOVE: 'CLASS'
    TAB_PANE: '.tab-pane'

  document_on_before: (event) =>
    @element = new @Element($(event.currentTarget).closest(@WRAPPER))

  document_on_after: (event) =>
    @element = null

  document_on: => [
    'click', @TOGGLE, (event) =>
      @element.toggle_nav_tabs()

    'click', @ADD, (event) =>
      @element.create()

    'click', @REMOVE, (event, button_remove) =>
      @element.destroy(button_remove)
  ]

  ready: =>
    return unless (@form = $('#new_action > form, #edit_action > form')).length

    @form.on 'pjax:submit', (event) =>
      unless (inputs = $(event.currentTarget).blank_inputs())
        return true
      if (input = inputs.filter(':focusable')).length
        return input.first().valid()
      input = inputs.first()
      first = input.closest(@TAB_PANE)
      last = input.closest("#{@TAB_PANE}:focusable")
      current = first
      loop
        $("a[href='##{current.attr('id')}']").tab('show')
        current = current.closest(@TAB_PANE)
        break unless current.length && last.length && current[0] != last[0]
      setTimeout ->
        input.valid()
      , $::tab.Constructor.TRANSITION_DURATION
      false

  leave: =>
    @form.off('pjax:submit') if @form?.length
    @form = null
