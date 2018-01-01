class Js.Pjax
  @CONTAINER: '#js_pjax_container'
  @TITLE: '#js_pjax_title'
  @VIRTUAL_FILE: '.js_pjax_virtual_file'
  @DEFAULTS: {
    method: 'GET'
    data: {}
    dataType: 'html'
    pjax: true
    scroll_to: 0
    scroll_wrapper: false
    push: true
    replace: false
    max_cache_length: 20
  }
  # Is pjax supported by this browser?
  @SUPPORTED: window.history && window.history.pushState && window.history.replaceState &&
    # pushState isn't reliable on iOS until 5.
    !navigator.userAgent.match(/((iPod|iPhone|iPad).+\bOS\s+[1-4]\D|WebApps\/.+CFNetwork)/)

  @state: null
  @previous_state: null
  @xhr: null
  @options: null
  @context: null

  UNSENT = 0
  DONE = 4
  DISABLE_WITH = '[data-disable-with]'

  initial_pop = true
  initial_url = window.location.href
  initial_state = window.history.state

  # Initialize @state if possible Happens when reloading a page and coming forward from a different session history.
  if initial_state && initial_state.id
    @state = initial_state

  # Non-webkit browsers don't fire an initial popstate event
  if 'state' of window.history
    initial_pop = false

  @initialize: (options = {}) =>
    $.error('cannot be used with jquery-ujs!') if $.rails?
    $.rails = {}

    $.error('cannot be used with turbolinks!') if window.Turbolinks?
    window.Turbolinks = {}

    @DEFAULTS = @DEFAULTS.merge(options)

    $.ajaxPrefilter (options, original_options, xhr) =>
      xhr.request_id = ++$.request_id
      unless options.crossDomain
        @csrf_protection(xhr)

    $(document).ready =>
      @refresh_csrf_tokens()

    # Workaround for jquery-ujs formnovalidate issue: https://github.com/rails/jquery-ujs/issues/316
    $(document).on 'click.pjax', '[formnovalidate]', ->
      $(this).closest('form').attr(novalidate: true).data(skip_validate: true)

    $(document).on 'submit.pjax', 'form', (event) =>
      form = $(event.currentTarget)
      button = $(document.activeElement)
      remote = button.data('remote') ? form.data('remote')
      return @disable_buttons() unless remote? && remote != false

      $.pjax.submit(event)
      false

    $(document).on 'click.pjax', 'a[data-method]', (event) =>
      link = $(event.currentTarget)
      href = link[0].href
      form = $("<form method='post' action='#{href}'></form>")
      inputs = "<input name='_method' value='#{link.data('method')}' type='hidden' />"
      csrf_token = $.csrf_token()
      csrf_param = $.csrf_param()
      if csrf_param? && csrf_token? && !$.is_cross_domain(href)
        inputs += "<input name='#{csrf_param}' value='#{csrf_token}' type='hidden' />"
      target = link.attr('target')
      form.attr('target', target) if target
      form.hide().append(inputs).appendTo('body')

      form.submit()
      false

    if @SUPPORTED
      @enable()
    else
      @disable()

  @enable: =>
    $.pjax = @send
    # Does nothing if already enabled.
    $.pjax.enable = _.noop
    $.pjax.disable = @disable
    $.pjax.click = @click
    $.pjax.submit = @submit
    $.pjax.reload = @reload
    $(window).on('popstate.pjax', @back_or_forward)

  @disable: =>
    # This is the case when a browser doesn't support pushState. It is
    # sometimes useful to disable pushState for debugging on a modern
    # browser.
    $.pjax = @fallback
    $.pjax.enable = @enable
    $.pjax.disable = _.noop
    $.pjax.click = @click
    $.pjax.submit = _.noop
    $.pjax.reload = @refresh
    $(window).off('popstate.pjax')

  @click: (event, options = {}) =>
    # Ignore event with default prevented
    return if event.isDefaultPrevented()

    # Middle click, cmd click, and ctrl click should open links in a new tab as normal.
    return if event.which > 1 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey

    target = event.currentTarget
    link = $(target)
    unless link.is('a')
      href = link.data('href')
      unless href
        throw "pjax click requires an anchor element or a href attribute"
      target = $.parse_location(href)
      link = $(target)

    # Ignore cross origin links
    return if $.is_cross_domain(target)

    # Ignore case when a hash is being tacked on the current URL
    return if target.href.includes('#') && @strip_hash(target) == @strip_hash(location)

    options = {url: target.href, target: target}.merge(options)
    unless @after_click(link, options) == false
      if options.active_wrapper
        @native_navigation(link, options.active_wrapper, exclude: options.active_exclude)
      if @SUPPORTED
        @send(options)
      else
        @fallback(options)
      event.preventDefault()
      @after_clicked(link, options)

  @submit: (event, options = {}) =>
    target = event.currentTarget
    form = $(target)
    unless form.is('form')
      throw "$.pjax.submit requires a form element"

    # TODO remotipart
    # if present_file_inputs
    #   @disable_buttons()
    #   unless (aborted = fire(form, 'ajax:aborted:file', [present_file_inputs]))
    #     @enable_buttons()
    #   return aborted
    # Can't handle file uploads, exit
    if form.find("input:file:not(#{@VIRTUAL_FILE})").length
      return
    else
      form.find("input:file#{@VIRTUAL_FILE}").each (index, element) -> $(element).clear_value()

    data = $(form[0]).serializeArray()
    button = $(document.activeElement)
    button_name = button.attr('name')
    button_data = if button_name then { name: button_name, value: button.val() } else null
    data.push(button_data) if button_data
    method = (button.attr('formmethod') || form.attr('method') || 'GET').upcase()
    url = button.attr('formaction') || form.attr('action')

    defaults = {
      method: method
      url: url
      target: target
      data: data
      crossDomain: $.is_cross_domain(url)
      push: method == 'GET'
    }
    type = button.attr('data-formtype') || form.attr('data-type')
    if type? && type != 'html'
      defaults.dataType = type
      defaults.pjax = false
    options = defaults.merge(options)
    Js.prepend_to options, 'beforeSend', @disable_buttons
    Js.prepend_to options, 'complete', @enable_buttons
    unless @after_submit(form, options) == false
      @send(options)
      event.preventDefault()
      @after_submitted(form, options)

  @reload: (options = {}) =>
    options = {url: window.location.href, push: false, replace: true, scroll_to: false}.merge(options)
    @send(options)

  @refresh: ->
    window.location.reload()

  @send: (options) =>
    options = $.ajaxSettings.deep_merge(@DEFAULTS, options)
    Js.prepend_to options, 'beforeSend', @on_before_send
    Js.prepend_to options, 'error', @on_error
    Js.prepend_to options, 'success', @on_success
    Js.prepend_to options, 'complete', @on_complete

    # Initialize @state for the initial page load. Assume we're using the container and options of the link we're
    # loading for the back button to the initial page. This ensures good back button behavior.
    unless @state
      @state = {
        id: $.now()
        url: window.location.href
        title: document.title
      }
      window.history.replaceState(@state, document.title)

    # We want the browser to maintain two separate internal caches: one for pjax'd partial page loads and one for normal
    # page loads. Without adding this secret parameter, some browsers will often confuse the two.
    if options.data.is_a(Array)
      options.data.push(name: '_pjax', value: @CONTAINER)
    else
      options.data._pjax = @CONTAINER

    @abort_if_pending()
    @xhr = $.ajax(options)

  @back_or_forward: (event) =>
    # TODO bug 3 pages: 1 back, reload, 1 fwd, 2 back, 1 fwd, 1 back (lost)
    @abort_if_pending() unless initial_pop

    state = event.originalEvent.state
    unless state?.id
      return initial_pop = false

    # When coming forward from a separate history session, will get an initial pop with a state we are already at.
    # Skip reloading the current page.
    return if initial_pop && initial_url == state.url

    @previous_state = @state
    if @previous_state
      # If popping back to the same state, just skip. Could be clicking back from hashchange rather than a pushState.
      return if @previous_state.id == state.id
      # Since state IDs always increase, we can deduce the navigation direction
      direction = if @previous_state.id < state.id then 'forward' else 'back'

    @context = $(@CONTAINER)
    unless @context.length
      @location_replace(location.href)
      return initial_pop = false

    contents = cache_mapping[state.id] || []
    if @previous_state
      # Cache current container before replacement and inform the cache which direction the history shifted.
      cache_pop(direction, @previous_state.id, @context.clone().contents())

    @after_popstate(state, direction)

    options = {
      id: state.id
      url: state.url
      push: false
      scroll_to: false
    }
    if contents.length
      @before_start(null, options)
      @state = state
      document.title = state.title if state.title?.present()
      @before_replace(contents)
      @context.html(contents)
      @after_end(null)
    else
      options.push = true
      options.replace = true
      @send(options)

    # Force reflow/relayout before the browser tries to restore the scroll position.
    @context[0].offsetHeight
    initial_pop = false

  @fallback: (options) =>
    method = options.method?.upcase() || 'GET'

    form = $('<form>', method: (if method == 'GET' then method else 'POST'), action: options.url, style: 'display:none')

    unless method == 'GET' || method == 'POST'
      form.append($('<input>', type: 'hidden', name: '_method', value: method.downcase()))

    $.flat_params(options.data).each (name, value) ->
      form.append($('<input>', type: 'hidden', name: name, value: value))

    $(document.body).append(form)
    form.submit()

  #### PRIVATE ####

  @on_before_send: (xhr, settings) =>
    @context = @find_context(settings)

    return false if @before_send(xhr, settings) == false

    url = $.parse_location(settings.url, pjax: true)
    @options = {
      method: settings.method || settings.type
      request_url: url.href
      hash: url.hash
    }.merge(settings)

    if @options.push && !@options.replace
      cache_push(@state.id, @context.clone().contents())
      window.history.pushState(null, "", @options.request_url)
    @before_start(xhr, settings)

  @on_error: (xhr, status, error) =>
    return if @before_error(xhr, status, error) == false
    return if status == 'abort'
    if @options.method == 'GET'
      container = @extract_container("", xhr)
      @location_replace(container.url)
    else if @options.pjax
      if (json = JSON.safe_parse(xhr.responseText))
        xhr.responseJSON = json
      else
        @on_success(xhr.responseText, status, xhr)

  @on_success: (data, status, xhr) =>
    return @after_success(data, status, xhr) unless @options.pjax

    @previous_state = @state

    # Find version identifier for the initial page load.
    current_version = $('meta[http-equiv="X-PJAX-VERSION"]').attr('content')
    latest_version = xhr.getResponseHeader('X-PJAX-VERSION')
    container = @extract_container(data, xhr)
    container.url = $.parse_location(container.url, hash: @options.hash).href

    # If there is a layout version mismatch, hard load the new url
    if current_version && latest_version && current_version != latest_version
      return @location_replace(container.url)

    # If the new response is missing a body, hard load the page
    unless container.contents
      return @location_replace(container.url)

    @state = {
      id: $.now()
      url: container.url
      title: container.title
    }
    if @options.push || @options.replace
      window.history.replaceState(@state, container.title, container.url)

    @blur()
    document.title = container.title if container.title?.present()
    @before_replace(container.contents)
    @context.html(container.contents)
    @focus()
    @scroll()
    @after_success(data, status, xhr)

  @on_complete: (xhr, status) =>
    @after_complete(xhr, status)
    @after_end(xhr)

  @after_click: (link, options) =>
    @fire(link, 'pjax:click', [options])

  @after_clicked: (link, options) =>
    @fire(link, 'pjax:clicked', [options])

  @after_submit: (form, options) =>
    @fire(form, 'pjax:submit', [options])

  @after_submitted: (form, options) =>
    @fire(form, 'pjax:submitted', [options])

  @before_send: (xhr, settings) =>
    @fire(@context, 'pjax:send', [xhr, settings])

  @before_start: (xhr, settings) =>
    @fire(@context, 'pjax:start', [xhr, settings])

  @before_error: (xhr, status, error) =>
    @fire(@context, 'pjax:error', [xhr, status, error, @options])

  @before_replace: (contents) =>
    @fire(@context, 'pjax:replace', [contents, @options], state: @state, previous_state: @previous_state)

  @after_success: (data, status, xhr) =>
    @fire(@context, 'pjax:success', [data, status, xhr, @options])

  @after_complete: (xhr, status) =>
    @fire(@context, 'pjax:complete', [xhr, status, @options])

  @after_end: (xhr) =>
    $.dom_ready()
    @fire(@context, 'pjax:end', [xhr, @options])

  @after_popstate: (state, direction) =>
    @fire(@context, 'pjax:popstate', [], state: state, direction: direction)

  @fire: (target, type, args, props = {}) ->
    props.relatedTarget = target
    event = $.Event(type, props)
    target.trigger(event, args)
    !event.isDefaultPrevented()

  @disable_buttons: ->
    # Slight timeout so that the submit button gets properly serialized
    setTimeout(->
      $(DISABLE_WITH).add_disabled()
    , 10)

  @enable_buttons: ->
    setTimeout(->
      $(DISABLE_WITH).add_disabled(false)
    , 10)

  @refresh_csrf_tokens: ->
    # Make sure that all forms have actual up-to-date tokens (cached forms contain old ones)
    $("form input[name='#{$.csrf_param()}']").val($.csrf_token())

  @csrf_protection: (xhr) ->
    # Make sure that every Ajax request sends the CSRF token
    token = $.csrf_token()
    xhr.setRequestHeader('X-CSRF-Token', token) if token

  @native_navigation: (link, active_wrapper, options = {}) ->
    [wrapper, active] = active_wrapper.split(/\.(\w+)$/, 2)
    unless wrapper?.present() && active?.present()
      # ex.: '.nav.nav-pills li.active' where '.nav.nav-pills li' is the wrapper selector and '.active' is the active class
      throw "pjax needs the wrapper selector followed by the active class like this: 'ul.any-class > li.active-class'"
    active_link = $("#{active_wrapper} a")
    active_href = active_link.attr('href')?.replace(location.origin, '')
    # TODO: migth be a link with data-href as well
    link_href = link.attr('href')
    if link_href.excludes(active_href)
      active_link.parent().removeClass(active);
      if options.exclude?.present() && options.exclude.excludes(link_href)
        link.parent().addClass(active)
      # back button cache: pjax does not blur elements outside the container
      link.blur()

  @find_context: (settings) =>
    if settings.pjax
      container = $(@CONTAINER)
      if container.length == 0
        throw "no pjax container for #{@CONTAINER}"
      container
    else
      $(settings.target)

  @extract_container: (data, xhr) =>
    # Prefer X-PJAX-URL header if it was set, otherwise fallback to using the original requested url.
    url = if (server_url = xhr.getResponseHeader('X-PJAX-URL'))
      # Used for redirects
      @options.push = true
      $.parse_location(server_url, pjax: true).href
    else
      @options.request_url

    container = { url: url }

    # If this is a full document, return fast
    return container if /<html/i.test(data)

    # Do not allow scripts within the container
    body = $($.parseHTML(data, document))

    # If response data is empty, return fast
    return container unless body.length

    container.contents = body
    container.title = body.filter(@TITLE).data('js')
    container

  @location_replace: (url) =>
    window.history.replaceState(null, "", @state.url)
    window.location.replace(url)

  @abort_if_pending: =>
    if @xhr?.readyState < DONE
      @xhr.onreadystatechange = _.noop
      @xhr.abort()

  @blur: =>
    # Only blur the focus if the focused element is within the container.
    if $.contains(@CONTAINER, document.activeElement)
      # Clear out any focused controls before inserting new page contents.
      try document.activeElement.blur() catch e then null

  @focus: =>
    # FF bug: Won't autofocus fields that are inserted via JS. This behavior is incorrect. So if theres no current
    # focus, autofocus the last field. http://www.w3.org/html/wg/drafts/html/master/forms.html
    autofocus = @context.find('input[autofocus], textarea[autofocus]').last()[0]
    if autofocus && document.activeElement != autofocus
      autofocus.focus()

  @scroll: =>
    # Ensure browser scrolls to the element referenced by the URL anchor
    scroll_to =
      if @options.hash?.present()
        name = decodeURIComponent(@options.hash[1..])
        target = document.getElementById(name) || document.getElementsByName(name)[0]
        $(target).offset().top if target
      else
        @options.scroll_to
    if scroll_to?.is_a(Number)
      $(window).scrollTop(scroll_to)
      if @options.scroll_wrapper != false
        wrapper = $(@options.scroll_wrapper)
        scroll_to += wrapper.scrollTop() if target
        wrapper.scrollTop(scroll_to)

  @strip_hash: (location) ->
    # Hash portion removed
    location.href.replace(/#.*/, '')

  cache_mapping       = {}
  cache_forward_stack = []
  cache_back_stack    = []

  cache_push = (id, value) =>
    cache_mapping[id] = value
    cache_back_stack.push(id)

    # Remove all entries in forward history stack after pushing a new page.
    trim_cache_stack(cache_forward_stack, 0)

    # Trim back history stack to max cache length.
    trim_cache_stack(cache_back_stack, @DEFAULTS.max_cache_length)

  cache_pop = (direction, id, value) =>
    cache_mapping[id] = value

    [push_stack, pop_stack] =
      if direction == 'forward'
        [cache_back_stack, cache_forward_stack]
      else
        [cache_forward_stack, cache_back_stack]

    push_stack.push(id)
    delete cache_mapping[id] if (id = pop_stack.pop())

    # Trim whichever stack we just pushed to the max cache length.
    trim_cache_stack(push_stack, @DEFAULTS.max_cache_length)

  trim_cache_stack = (stack, length) ->
    while (stack.length > length)
      delete cache_mapping[stack.shift()]
