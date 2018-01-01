class RailsAdmin.InfiniteScrollConcept
  constants: ->
    CONTAINER: '#js_bulk_form'
    LINK: 'CLASS'
    SEPARATOR: 'CLASS'

  document_on: => [
    'click', @LINK, (event, target) =>
      return if (@link_wrapper = target).find('a').has_disabled()

      $.ajax(
        url: @link_wrapper.data('url')
        disabled: "#{@LINK} a"
        action_error: "#{@LINK} a"
        success: (data) =>
          @prepend_old_list_and_replace_container(data)
        complete: ->
          $.dom_ready()
      )
  ]

  ready: =>
    return unless (link_wrapper = $(@LINK)).length

    if link_wrapper.hasClass('disabled')
      link_wrapper.find('a').add_disabled()

  #### PRIVATE ####

  # TODO Bug --> when ending unavailable, the list becomes blank
  # --> maybe check received number equals max page size
  prepend_old_list_and_replace_container: (data) =>
    index = $("<div>").html(data)
    new_container = index.find(@CONTAINER)
    new_list = new_container.find('tbody:last > tr:first')
    new_list.prepend($('tbody:last').html())
    new_list.find('tr:last').addClass(@SEPARATOR_CLASS)
    $(@CONTAINER).html(new_container.html())
