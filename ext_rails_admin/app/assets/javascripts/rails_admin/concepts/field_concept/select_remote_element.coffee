class RailsAdmin.FieldConcept::SelectRemoteElement extends RailsAdmin.FieldConcept::SelectElement
  constructor: (@input) ->
    { url_params, @required } = @input.data('js')
    @url = Routes.url_for('index', url_params)
    @control = $(
      input @SEARCH_BOX,
        type: 'search'
        placeholder: I18n.t("placeholder")
        class: 'form-control'
        data: { id: @input.attr('id') }
        autocomplete: 'off'
    )
    @input.after(@control)
    @cached_keys = {}
    @cached_values = {}
    @debounced_fetch = _.debounce(@remote_fetch, 300)

  render: =>
    value = @input.find(':selected')[0].text || ''
    @render_list()
    @update_list(value)
    @show_field(value)

  update_on_keydown: (event) =>
    # TODO must consider SHIFT+TAB as well
    item = $(@SELECTED)
    switch event.which
      when $.ui.keyCode.ESCAPE
        @control.blur()

      when $.ui.keyCode.ENTER
        @enter(item)
        @control.blur()

      when $.ui.keyCode.UP
        @up(item)
        event.preventDefault()

      when $.ui.keyCode.DOWN
        @down(item)
        event.preventDefault()

      when $.ui.keyCode.PAGE_UP
        @first(item)

      when $.ui.keyCode.PAGE_DOWN
        @last(item)
      else
        return
    @scroll()

  update_on_keyup: (event) =>
    query = @control.val()
    switch event.which
      when $.ui.keyCode.DELETE
        @update_list(query)

      when $.ui.keyCode.BACKSPACE
        if @control.cursor_end() == query.length && /\s$/.match(query)
          return
        else
          @update_list(query)
      else
        char = String.fromCharCode(event.which)
        if /[\w ]/.match(char)
          @update_list(query)
        else
          return
    @scroll()

  update_input: ({ value, label }) =>
    if (options = @input.children()).length > 1
      options.last().remove()
    unless value == @BLANK
      @input.append(option selected: true, value: value, -> label)
      @cached_values[value] = label.to_s()
    @input.change()

  close: =>
    @input.removeClass(@HIDE_CLASS)
    @control.removeClass(@SHOW_CLASS)
    $(@LIST_WRAPPER).remove()
    @keep_focus = false

  #### PRIVATE ####

  render_list: =>
    $(@LIST_WRAPPER).remove()
    list_wrapper = $(
      div @LIST_WRAPPER, data: { id: @input.attr('id') }, =>
        div '.dropdown.open.input-group.col-sm-12', =>
          ul @LIST, class: 'dropdown-menu', style: "max-height: #{$(window).height()}px"
    )
    @control.after(list_wrapper)
    list_wrapper.find(@LIST)

  update_list: (query) =>
    query = query.downcase()
    if (data = @cache_fetch(query))
      @build_list(query, data)
    else
      @debounced_fetch(query)

  show_field: (value) =>
    @control.addClass(@SHOW_CLASS).attr(required: @required).val(value)
    @input.addClass(@HIDE_CLASS)
    spacer = $(div @SPACER)
    @input.after(spacer).hide()
    setTimeout =>
      spacer.remove()
      @input.show()
    @control.click().focus().cursor_end(true)
    @control.valid()

  enter: (item) =>
    if item.length
      @update_input(item.data())

  down: (item) =>
    if item.length
      if (next = item.next(@ITEM)).length
        item.removeClass('active')
        next.addClass('active')
    else
      $(@ITEM).first().addClass('active')

  up: (item) =>
    if item.length
      if (prev = item.prev(@ITEM)).length
        item.removeClass('active')
        prev.addClass('active')
    else
      $(@ITEM).first().addClass('active')

  first: (item) =>
    if item.length
      item.removeClass('active')
    $(@LIST).find(@ITEM).first().addClass('active')

  last: (item) =>
    if item.length
      item.removeClass('active')
    $(@LIST).find(@ITEM).last().addClass('active')

  scroll: =>
    $(@LIST).scroll_to(@SELECTED)

  remote_fetch: (query) =>
    @xhr.abort() if @xhr?
    @xhr = $.ajax(
      url: @url
      data: { query }
      dataType: 'json'
      content_error: "#{@LIST_WRAPPER} .modal-content"
      success: (data, status, xhr) =>
        if xhr.request_id == $.request_id
          @build_list(query, data)
    )

  build_list: (query, data) =>
    list = $(@LIST)
    list.html('')
    @append_item(list, query, value: @BLANK, label: @BLANK)
    @cache_write(query, data).each (option) =>
      @append_item(list, query, option)

  cache_fetch: (query) =>
    if query.blank()
      return [] if @cached_keys.empty()
    else
      return unless @cached_keys[query]
    @filtered_values(query)

  cache_write: (query, data) =>
    @cached_keys[query] = true
    data.each (option) =>
      @cached_values[option.value] = option.label.to_s()
    @filtered_values(query)

  filtered_values: (query) ->
    values = @cached_values.each_with_object (value, label, memo) ->
      unless value.blank() || label.downcase().excludes(query)
        memo.push { value, label }
    , []
    values.sort_by('label')

  append_item: (list, query, { value, label }) =>
    query = query.safe_regex()
    label = label.safe_text()
    item =
      if (blank = (value == @BLANK))
        span @BLANK, style: 'opacity: 0'
      else if (exact = ///^#{query}$///i.match(label))
        label
      else
        label.gsub(///(#{query})///i, "<strong>$1</strong>")

    selected = 'active' if (blank && query.blank()) || exact

    list.append(
      li @ITEM, class: selected, data: { value, label }, ->
        a item.html_safe(true), href: '#'
    )
