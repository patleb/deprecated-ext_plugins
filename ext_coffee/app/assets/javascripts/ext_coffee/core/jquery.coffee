jQueryTags = jQuery.fn.init
jQuery.fn.init = (selector, context, root) ->
  if selector?.html_safe?()
    selector = selector.to_s()
  new jQueryTags(selector, context, root)

jQuery.extend $,
  REPORT_VALIDITY: $('<form>')[0].reportValidity?
  PROGRESS_BAR_DEBOUNCE: 500
  progress_bar_timeout: null
  ajax_flags: {}
  ready_list: []
  request_id: 0
  class_name: 'jQuery'

jQuery.define_singleton_methods
  dom_ready: (args...) ->
    # Used to trigger all ready events
    $($.ready_list).each(-> this(args...))

  unique_id: (size) ->
    id = $.now().to_s()
    id = id[(10 - size + 1)..10] if size? && size > 0 && size <= 10
    id

  add_flags: (flags) ->
    for name, ajax of flags
      $.add_flag(name, ajax)

  add_flag: (name, ajax) ->
    $.ajax_flags[name] = ajax

    css_class = "js_#{name}"
    $[name.toUpperCase()] = css_class

    $.fn["add_#{name}"] = (add = true) ->
      action = if add then 'add' else 'remove'
      this["#{action}Class"](css_class)

    $.fn["has_#{name}"] = ->
      this.hasClass(css_class)

  flat_params: (data) ->
    params = {}
    if data.is_a(String)
      data = decodeURIComponent(data).sub(/^\?/, '')
      data.split('&').except('').each (pair) ->
        [name, value] = pair.split('=')
        if /\[\]$/.match(name)
          params[name] ?= []
          params[name].push value
        else
          params[name] = value
    else
      params = $.flat_params($.param(data))
    params

  merge_params: (object, sources...) ->
    object.merge(sources.map (source) -> $.flat_params(source))

  load_progress_bar: ->
    unless $.progress_bar_timeout?
      $.progress_bar_timeout = setTimeout(->
        NProgress.start()
      , $.PROGRESS_BAR_DEBOUNCE)

  clear_progress_bar: ->
    NProgress.done()
    clearTimeout($.progress_bar_timeout)
    $.progress_bar_timeout = null

  parse_location: (url, options = {}) ->
    # HTMLAnchorElement that acts like Location
    if url.is_a(String)
      location = document.createElement('a')
      location.href = url
    else
      location = url
    # Strip pjax internal query params from parsed URL and sanitize url.href String.
    if options.pjax
      location.search = location.search.gsub(/([?&])(_pjax|_)=[^&]*/, '')
      location.href = location.href.sub(/\?($|#)/, '$1')
    else
      # IE bug workaround.
      location.href = location.href
    # Add hash value to location object
    location.hash = options.hash if options.hash
    location

  csrf_token: ->
    # Up-to-date Cross-Site Request Forgery token
    $('meta[name=csrf-token]').attr('content')

  csrf_param: ->
    # URL param that must contain the CSRF token
    $('meta[name=csrf-param]').attr('content')

  is_cross_domain: (url) ->
    origin = document.createElement('a')
    origin.href = location.href
    check = (origin, request) ->
      # If URL protocol is false or is a string containing a single colon
      # *and* host are false, assume it is not a cross-domain request
      # (should only be the case for IE7 and IE compatibility mode).
      # Otherwise, evaluate protocol and host of the URL against the origin
      # protocol and host.
      !(
        ((!request.protocol || request.protocol == ':') && !request.host) ||
          ("#{origin.protocol}//#{origin.host}" == "#{request.protocol}//#{request.host}")
      )
    return check(origin, url) unless url.is_a(String)

    request = document.createElement('a')
    try
      request.href = url
      # This is a workaround to a IE bug.
      request.href = request.href
      check(origin, request)
    catch e
      # If there is an error parsing the URL, assume it is crossDomain.
      true

  form_for: (data = {}) ->
    { utf8: "✓", "#{$.csrf_param()}": $.csrf_token() }.merge(data)

  form_valid: (inputs) ->
    inputs.to_a().all (input) ->
      $(input).valid()

  form_invalid: (inputs) ->
    !$.form_valid(inputs)

jQuery.prepend_to_singleton_methods
  ajax: (options) ->
    unless options.dataType
      options.dataType = 'html'

    unless options.progress == false
      Js.prepend_to options, 'beforeSend', (xhr, settings) ->
        $.load_progress_bar()
      Js.prepend_to options, 'complete', (xhr, status) ->
        $.clear_progress_bar()

    if options.pjax
      Js.prepend_to options, 'beforeSend', (xhr, settings) ->
        xhr.setRequestHeader('X-PJAX', 'true')
    else
      Js.prepend_to options, 'beforeSend', (xhr, settings) ->
        xhr.setRequestHeader('Accept', 'text/javascript')

    $.ajax_flags.each (name, ajax_flag) ->
      { after_send, after_value } = ajax_flag
      if options[name]
        Js.prepend_to options, 'beforeSend', (xhr, settings) ->
          $(options[name])["add_#{name}"](!after_value)
        Js.append_to options, after_send, (args...) ->
          $(options[name])["add_#{name}"](after_value)

jQuery.define_methods
  is_a: (klass) ->
    klass == jQuery

  to_a: ->
    this.toArray()

  to_s: ->
    this[0].outerHTML

  each_with_object: (f_item_memo_index_self, accumulator) ->
    f = (memo, item, index, self) ->
      f_item_memo_index_self($(item), memo, index, self)
      accumulator
    _.reduce(this, f, accumulator)

  clone_template: (handler = null) ->
    clone = this.children().first().clone()
    handler(clone) if handler?
    clone

  valid: ->
    if this.closest('form').data('skip_validate') || this.attr('novalidate') || this[0].checkValidity?()
      true
    else if $.REPORT_VALIDITY
      this[0].reportValidity()
    else
      # check remotely
      true

  invalid: ->
    !this.valid()

  classes: ->
    this.prop('class').split(' ').except('')

  find_first: (selector) ->
    result = $()
    search = true
    if selector?.present()
      this.each ->
        queue = []
        queue.push($(this))
        while queue.length && search
          queue.shift().children().each ->
            child = $(this)
            if child.is(selector)
              result.push(child[0])
              search = false
            else
              queue.push(child)
        search
    result

  find_all: (selector, { remove = false } = {}) ->
    list = this.find(selector).addBack(selector)
    if remove
      excluded = list.remove()
      [list, this.not(excluded)]
    else
      list

  blank_inputs: (selector = 'input[name][required],textarea[name][required],select[name][required]', blank = true) ->
    found_inputs = $()
    checked_radio_button_names = {}
    for input in this.find(selector)
      input = $(input)
      if input.is('input[type="radio"]')
        # Don't count unchecked required radio as blank if other radio with same name is checked,
        # regardless of whether same-name radio input has required attribute or not. The spec
        # states https://www.w3.org/TR/html5/forms.html#the-required-attribute
        radio_name = input.attr('name')
        # Skip if we've already seen the radio with this name.
        unless checked_radio_button_names[radio_name]
          # If none checked
          unless this.find("input[type='radio']:checked[name='#{radio_name}']").length
            radios_for_name_with_none_selected = this.find("input[type='radio'][name='#{radio_name}']")
            found_inputs = found_inputs.add(radios_for_name_with_none_selected)
          # We only need to check each name once.
          checked_radio_button_names[radio_name] = radio_name
      else
        value_to_check =
          if input.is('input[type=checkbox],input[type=radio]')
            input.is(':checked')
          else
            !!input.val()
        unless value_to_check == blank
          found_inputs = found_inputs.add(input)
    if found_inputs.length
      found_inputs
    else
      false

  present_inputs: (selector = 'input[name][required],textarea[name][required],select[name][required]') ->
    this.blank_inputs(selector, false)

  get_value: ->
    switch this.attr('type')
      when 'checkbox', 'radio'
        this.is(':checked')
      else
        this.val()

  clear_value: ->
    switch this.attr('type')
      when 'checkbox', 'radio'
        this.prop(checked: false)
    this.val(null)

  cursor_start: (move = false) ->
    if move
      this[0].setSelectionRange?(0, 0)
      this
    else
      this[0].selectionStart || 0

  cursor_end: (move = false) ->
    if move
      caret_position = this.val().length * 2
      this[0].setSelectionRange?(caret_position, caret_position)
      this
    else
      this[0].selectionEnd || 0

  scroll_to: (item) ->
    if (item = $(item)).length
      this.scrollTop(this.scrollTop() - this.position().top + item.position().top)
    this

  has_scroll_y: ->
    this[0].scrollHeight > this[0].clientHeight

  has_scroll_x: ->
    this[0].scrollWidth > this[0].clientWidth

jQuery.decorate_methods
  ready: ->
    handler = arguments[0]
    $.ready_list.push(handler)

    args = Array.prototype.slice.call(arguments, 1)
    this.super.apply(this, [-> handler(args...)])

  submit: (args...) ->
    if args.length && !args[0].is_a(String)
      this.super.apply(this, args)
    else if this.attr('novalidate') || this[0].checkValidity?()
      this.super.apply(this, [])
    else if $.REPORT_VALIDITY
      this[0].reportValidity()
    else
      this.find("[type='submit'][name='#{args.shift() || '_save'}']").click()

jQuery.add_flags
  disabled:         { after_send: 'complete', after_value: false }
  once:             { after_send: 'complete', after_value: false }
  input_success:    { after_send: 'success',  after_value: true }
  input_error:      { after_send: 'error',    after_value: true }
  content_success:  { after_send: 'success',  after_value: true }
  content_error:    { after_send: 'error',    after_value: true }
  action_error:     { after_send: 'error',    after_value: true }

jQuery.prepend_to_methods
  add_disabled: (add = true) ->
    this.prop(disabled: add)
