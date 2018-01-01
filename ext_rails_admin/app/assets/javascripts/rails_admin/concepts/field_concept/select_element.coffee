# TODO refactor with remote_concern and multi_concern which are included instead of inherited
# TODO mobile correction https://gist.github.com/brandonaaskov/1596867

class RailsAdmin.FieldConcept::SelectElement
  constants: =>
    REMOTE: 'CLASS'
    SEARCH_BOX: 'CLASS'
    PLACEHOLDER: 'CLASS'
    CONTROL: => "#{@SEARCH_BOX},#{@PLACEHOLDER}"
    LIST_WRAPPER: 'ID'
    LIST: 'ID'
    ITEM: 'CLASS'
    SELECTED: => "#{@LIST} > .active"
    SPACER: 'CLASS'
    SHOW: 'CLASS'
    HIDE: 'CLASS'
    BLANK: '__BLANK__'

  document_on: => [
    'focus', @REMOTE, (event, target) =>
      @c.fields[target.attr('id')].render()

    'focus', @PLACEHOLDER, (event, target) =>
      select = @c.fields[target.data('id')]
      select.render() unless select.keep_focus

    'blur', @CONTROL, (event, target) =>
      select = @c.fields[target.data('id')]
      select.close() unless select.keep_focus

    'keydown', @CONTROL, (event, target) =>
      @c.fields[target.data('id')].update_on_keydown(event)

    'keyup', @CONTROL, (event, target) =>
      @c.fields[target.data('id')].update_on_keyup(event)

    'mousedown', @ITEM, (event) =>
      @c.fields[$(@LIST_WRAPPER).data('id')].keep_focus = (event.which == 1)

    'click', @ITEM, (event, target) =>
      select = @c.fields[$(@LIST_WRAPPER).data('id')]
      select.update_input(target.data())
      select.close() if select.keep_focus
  ]

  render:            -> throw 'NotImplementedError'
  update_on_keydown: -> throw 'NotImplementedError'
  update_on_keyup:   -> throw 'NotImplementedError'
  update_input:      -> throw 'NotImplementedError'
  close:             -> throw 'NotImplementedError'

  update_select: (input, { value, label, multiple = false }) ->
    if (option = input.find("[value='#{value.safe_text()}']")).length
      # EDIT
      option.text(label)
    else
      # NEW
      input.append $('<option>', value: value, text: label)
    if multiple
      values = input.val()
      values.push(value)
      input.val(values)
    else
      input.val(value)
    input.change()
