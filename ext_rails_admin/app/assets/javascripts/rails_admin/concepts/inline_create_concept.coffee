class RailsAdmin.InlineCreateConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    LINK: 'CLASS'
    ROW: 'CLASS'
    CELL: 'CLASS'
    SAVE: 'CLASS'
    CANCEL: 'CLASS'
    CONTENT_STATE: '.table thead'

  document_on: => [
    'click', @LINK, (event, link) =>
      if $('#index_action').length
        unless link.hasClass('active')
          @show_inputs()
      else
        url = Routes.url_for('new', model_name: @abstract_model())
        $.pjax(url: url)

    'click', @CANCEL, (event) =>
      @clear_inputs()

    'click', @SAVE, (event, target) =>
      return if (@button = target).has_once()

      if $.form_valid(@inputs)
        @send_form()

    'focus', "#{@CELL} input", (event) =>
      @disable_sort()
  ]

  ready: =>
    @row = $(@ROW)
    @inputs = @row.find('input')

  #### PRIVATE ####

  send_form: =>
    inputs = @inputs.each_with_object (input, result) =>
      result[input.attr('name')] = input.get_value()
    , {}
    form = $.form_for(inputs)
    url = Routes.url_for('new', model_name: @abstract_model(), inline: true)
    $.pjax(
      url: url
      method: 'POST'
      data: form
      push: false
      once: @SAVE
      content_error: @CONTENT_STATE
      content_success: @CONTENT_STATE
      error: (xhr, status, error) ->
        Flash.render('error', xhr.responseJSON.flash.error)
    )

  show_inputs: =>
    @row.show()
    $('li[class*="_collection_link"]').removeClass('active')
    $('li.new_collection_link').addClass('active')
    $(@CONTENT_STATE).add_content_success(false)
    @disable_sort()

  clear_inputs: =>
    @inputs.clear_value()
    Flash.clear()
    @row.hide()
    $('li.new_collection_link').removeClass('active')
    $('li.index_collection_link').addClass('active')
    $(@CONTENT_STATE).add_content_error(false)
    @enable_sort()
