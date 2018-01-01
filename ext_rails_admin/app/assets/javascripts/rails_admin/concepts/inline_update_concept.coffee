class RailsAdmin.InlineUpdateConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    WRAPPER: 'CLASS'
    READONLY: 'CLASS'

  document_on: => [
    'click', "#{@WRAPPER} input[readonly]", (event, input) =>
      @show_input(input)

    'blur', @WRAPPER, (event, target) =>
      return if (@input_wrapper = target).has_once()

      @input = @input_wrapper.find('input')

      if @input.invalid()
        @show_error()
      else if @input.get_value().to_s() == @input.attr('value')
        @show_text()
      else
        @send_form()
  ]

  ready: =>
    return unless $(@WRAPPER).length

    $(window).on 'resize.inline_update', _.throttle(@reset_width, 100)

  leave: ->
    $(window).off 'resize.inline_update'

  #### PRIVATE ####

  send_form: (field_value) =>
    id = @input.attr('id').to_i()
    url = Routes.url_for('edit', model_name: @abstract_model(), id: id, inline: true)
    form = $.form_for("#{@input.attr('name')}": @input.get_value())
    $.ajax(
      url: url
      method: 'PUT'
      data: form
      dataType: 'json'
      once: @WRAPPER
      input_error: @input_wrapper
      input_success: @input_wrapper
      success: (data, status, xhr) =>
        @input.attr(value: data.value).val(data.value)
        @show_text()
      error: (xhr, status, error) =>
        if xhr.responseJSON?
          Flash.render('error', xhr.responseJSON.flash.error)
          @show_error()
    )

  show_error: =>
    @input_wrapper.add_input_error()
    @input.attr(placeholder: @input.attr('value'))

  show_text: =>
    Flash.clear()
    @input.prop(readonly: true)
    @input.removeAttr('placeholder')
    @input_wrapper.addClass(@READONLY_CLASS)
    @input_wrapper.add_input_error(false)
    @enable_sort()

  show_input: (input) =>
    input_wrapper = input.closest(@WRAPPER)
    @freeze_width(input_wrapper)
    input.prop(readonly: false).click().focus()
    input_wrapper.removeClass(@READONLY_CLASS)
    input_wrapper.add_input_success(false)
    @disable_sort()

  freeze_width: (input_wrapper) =>
    current_width = input_wrapper.outerWidth()
    input_wrapper.css(width: current_width)

  reset_width: =>
    $(@WRAPPER).removeAttr('style')
