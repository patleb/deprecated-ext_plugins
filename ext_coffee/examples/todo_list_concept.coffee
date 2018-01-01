class Examples.TodoListConcept
  constants: ->
    WRAPPER: 'ID'
    ITEMS: 'CLASS'
    ITEM: 'CLASS'
    ADD: 'CLASS'
    REMOVE: 'CLASS'

  document_on: => [
    'keydown', @ADD, (event, input) =>
      if event.which == $.ui.keyCode.ENTER
        event.preventDefault()
        if (todo = input.val()).present()
          @todos[$.unique_id(6)] = todo.strip()
          input.val('')
          @render()

    'click', @REMOVE, (event, link) =>
      delete @todos[link.data('id')]
      @render()
  ]

  ready: =>
    return unless (@list = $(@WRAPPER).find(@ITEMS)).length
    @todos ||= {}
    @render()

  render: =>
    @list.html @todos.html_map (id, todo) =>
      li @ITEM, id: id, => [
        span -> todo
        a @REMOVE, '×', href: '#', data: { id: id }
      ]
