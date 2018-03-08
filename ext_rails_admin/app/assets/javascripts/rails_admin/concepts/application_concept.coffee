# TODO https://github.com/basecamp/local_time
# _.reduce($._data( $(document)[0], "events" ), function(sum, value, key) {return sum + value.length;}, 0);

@RailsAdmin ||= {}

class RailsAdmin.ApplicationConcept
  sort_header_timeout = null

  constants: ->
    WINDOW: 'ID'
    TITLE: 'ID'

  document_on: -> [
    'keydown', '#new_action > form, #edit_action > form, #js_bulk_form', (event) ->
      if event.which == $.ui.keyCode.ENTER && !$(event.target).is("textarea")
        event.preventDefault()

    'click', '.js_application_bulk_action', (event, target) ->
      $('#bulk_action').val(target.data('action'))
      $('#js_bulk_form').submit()
      false

    'click', '.js_application_remove_file', (event, link) ->
      link.siblings('[type=checkbox]').click()
      link.siblings('.toggle').toggle('slow')
      link.toggleClass('btn-danger btn-info')
      false

    'click.continue', '.js_application_export_select_all', (event, target) ->
      inputs = target.closest(".control-group").find(".controls").find("input").each (index, input) ->
        input = $(input)
        input.prop(checked: !input.prop('checked'))

    "click.continue", ".js_application_bulk_toggle", (event, target) ->
      $("#index_action [name='bulk_ids[]']").prop "checked", target.is(":checked")

    'click.continue', '.form-horizontal legend', (event, target) ->
      if target.has('i.icon-chevron-down').length
        target.siblings('.control-group:visible').hide('slow')
        target.children('i').toggleClass('icon-chevron-down icon-chevron-right')
      else
        if target.has('i.icon-chevron-right').length
          target.siblings('.control-group:hidden').show('slow')
          target.children('i').toggleClass('icon-chevron-down icon-chevron-right')

    'click.continue', '#fields_to_export label input#check_all', ->
      elems = $('#fields_to_export label input')
      if $('#fields_to_export label input#check_all').is ':checked'
        $(elems).prop(checked: true)
      else
        $(elems).prop(checked: false)
  ]

  ready: =>
    $('.animate-width-to').each ->
      length = $(this).data("animate-length")
      width = $(this).data("animate-width-to")
      $(this).animate(width: width, length, 'easeOutQuad')

    $('.form-horizontal legend').has('i.icon-chevron-right').each ->
      $(this).siblings('.control-group').hide()

  abstract_model: ->
    $('#js_abstract_model').data('js')

  enable_sort: =>
    unless sort_header_timeout
      sort_header_timeout = setTimeout(->
        $('th._header._pjax').removeClass('_header _pjax').addClass('header pjax')
      , 200)

  disable_sort: =>
    $('th.header.pjax').removeClass('header pjax').addClass('_header _pjax')
    clearTimeout(sort_header_timeout)
    sort_header_timeout = null
