#= require rails_admin/concepts/field_concept/select_remote_element

class RailsAdmin.FieldConcept::SelectMultiElement extends RailsAdmin.FieldConcept::SelectRemoteElement
  constants: =>
    TOKEN_LIST: 'CLASS'
    TOKEN_ITEM: 'CLASS'
    CHOSE_ALL: 'CLASS'
    CLEAR_ALL: 'CLASS'
    RESET: 'CLASS'
    REMOVE_SPACER: 'CLASS'
    REMOVE: => "#{@TOKEN_ITEM} > .delete"
    EDIT: => "#{@TOKEN_ITEM} > .label"

  document_on: => [
    'click', @CHOSE_ALL, (event, target) =>
      @c.fields[target.data('id')].chose_all_options()

    'click', @CLEAR_ALL, (event, target) =>
      @c.fields[target.data('id')].remove_all_tokens()

    'click', @RESET, (event, target) =>
      @c.fields[target.data('id')].reset_tokens()

    'click', @REMOVE, (event, target) =>
      token = target.closest(@TOKEN_ITEM)
      @c.fields[token.closest(@TOKEN_LIST).data('id')].remove_token(token.data())

    'dblclick', @EDIT, (event, target) =>
      token = target.closest(@TOKEN_ITEM)
      @c.fields[token.closest(@TOKEN_LIST).data('id')].render_form(token.data())
  ]

  constructor: (@input) ->
    @values = @input.find('option').to_a().reject(value: '').map ({ value, text, selected }, index) ->
      { value: value.safe_text(), label: text.safe_text(), index: index, selected: selected, initial: selected }
    @placeholder = $('<select>', class: "#{@PLACEHOLDER_CLASS} form-control", 'data-id': @input.attr('id'))
    @input.after(@placeholder)
    @token_list = $('<div>', class: @TOKEN_LIST_CLASS, 'data-id': @input.attr('id'), style: "max-height: #{$(window).height()}px")
    @placeholder.after(@token_list)
    { @edit_params, @removable, @sortable } = @input.data('js') || {}
    @configure_sortable() if @sortable
    @reset_tokens()
    @set_control()

  render: =>
    list = @render_list()
    @append_item(list, '', value: @BLANK, label: @BLANK)
    @values.select(selected: false).each (option) =>
      @append_item(list, '', option)
    @show_field()
    @sm.reset(element: this)

  render_form: ({ value }) =>
    if @edit_params
      params = { id: value }.merge(@edit_params)
      url = Routes.url_for('edit', params)
      RailsAdmin.ModalFormConcept.render_modal(url, @input.id)

  update_on_keydown: (event) =>
    super
    if event.which == $.ui.keyCode.SPACE
      event.preventDefault()

  update_on_keyup: (event) =>
    if /[\w ]/.match(char = String.fromCharCode(event.which).downcase())
      @sm.trigger('keypress', new_char: char)

  update_input: ({ value, label }) =>
    return if value == @BLANK
    [value, label] = [value.to_s().safe_text(), label.safe_text()]

    @update_select(@input, { value, label, multiple: true })
    if (option = @values.find(value: value))
      option.selected = true
      { index, initial } = option
      if (old_token = @token_list.find("[data-value='#{value}']")).length
        # EDIT
        option.label = label
        new_token = @render_token({ value, label, index, initial })
        old_token.replaceWith(new_token)
      else
        @append_token({ value, label, index, initial })
    else
      # NEW
      [index, initial] = [@values.length, false]
      @values.push { value, label, index, initial, selected: true }
      @append_token({ value, label, index, initial })

  reset_tokens: =>
    @remove_all_tokens()
    values = @values.select(initial: true).each_with_object (option, memo) =>
      memo.push(option.value)
      option.selected = true
      @append_token(option.merge(skip_refresh: true))
    , []
    @append_token_refresh()
    @input.val(values)

  chose_all_options: =>
    values = @values.select(selected: false).each_with_object (option, memo) =>
      memo.push(option.value)
      option.selected = true
      @append_token(option.merge(skip_refresh: true))
    , @input.val()
    @append_token_refresh()
    @input.val(values)

  remove_all_tokens: =>
    @values.select(selected: true).each (option) =>
      @remove_token(option.merge(skip_refresh: true))
    @remove_token_refresh()

  remove_token: ({ value, skip_refresh = false }) =>
    value = value.to_s()
    values = @input.val().except(value)
    @input.val(values)
    @values.find(value: value).selected = false
    @token_list.find("[data-value='#{value}']").remove()
    @remove_token_refresh() unless skip_refresh

  close: =>
    $(@LIST_WRAPPER).remove()
    @keep_focus = false

  #### PRIVATE ####

  sm: new Js.StateMachine 'select_multi_keyup', {
    initialize: (sm, { element } = {}) ->
      sm.element = element
      sm.keyups = ''
      sm.update_on_keyup_timeout = null
    initial: 'no_char'
    triggers:
      keypress:
        '*': 'new_char'
        before: (sm, { new_char }) ->
          clearTimeout(sm.update_on_keyup_timeout)

          sm.keyups += new_char
          item = sm.element.values.find ({ value, label, selected }) ->
            !selected && label.downcase().starts_with(sm.keyups)
          if item && (option = $(sm.element.LIST).find("[data-value='#{item.value}']")).length
            $(sm.element.SELECTED).removeClass('active')
            option.addClass('active')

          sm.update_on_keyup_timeout = setTimeout ->
            sm.trigger('timeout')
          , 1000
      timeout:
        '*': 'no_char'
        before: (sm) ->
          sm.keyups = ''
          sm.update_on_keyup_timeout = null
  }

  configure_sortable: =>
    @token_list.sortable(
      items: "> #{@TOKEN_ITEM}"
      cursorAt: { top: 52 }
      axis: 'y'
      update: (event, ui) =>
        @reorder_select()
    )

  set_control: =>
    @control = @placeholder

  show_field: =>
    # necessary for removing focus on the select empty list
    @keep_focus = true
    @placeholder.hide()
    setTimeout =>
      @placeholder.show().focus()
      @keep_focus = false

  append_token: ({ value, label, index, initial, skip_refresh = false }) =>
    token = @render_token({ value, label, index, initial })
    if @sortable
      @token_list.append(token)
    else if (previous_token = @token_list.find(@TOKEN_ITEM).filter(-> $(this).data('index') < index)).length
      previous_token.last().after(token)
    else
      @token_list.prepend(token)
    @append_token_refresh() unless skip_refresh

  append_token_refresh: =>
    if @sortable
      @reorder_select()
      @token_list.sortable('refresh')

  remove_token_refresh: =>
    if @sortable
      @token_list.sortable('refresh')

  render_token: ({ value, label, index, initial }) =>
    removable_link = 'delete' if @removable || !initial
    initial_warning = 'icon-danger' if initial
    "
      <p class='#{@TOKEN_ITEM_CLASS}' data-value='#{value}' data-index='#{index}' style='max-width: #{@input.outerWidth()}px'>
        <a href='#' class='#{removable_link || @REMOVE_SPACER_CLASS}'>
          <i class='fa fa-trash-o fa-fw #{initial_warning || ''}'></i>
        </a>
        <span class='label label-info'>#{label}</span>
      </p>
    "

  reorder_select: =>
    values = @input.val()
    unneeded_values = @values.dup()
    selected_values = @token_list.find(@TOKEN_ITEM).to_a().map (token) ->
      { value, label } = unneeded_values.delete_if((option) -> option.value == $(token).data('value').to_s())[0]
    @input.find("option[value!='']").remove()
    [selected_values, unneeded_values].each (options) =>
      options.each ({ value, label }) =>
        @input.append $('<option>', value: value, text: label)
    @input.val(values)
