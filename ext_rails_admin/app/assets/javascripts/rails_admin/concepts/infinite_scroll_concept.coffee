#= require rails_admin/concepts/table_concept

class RailsAdmin.InfiniteScrollConcept
  constants: ->
    CONTAINER: '#js_bulk_form'
    LINK: 'CLASS'
    SEPARATOR: 'CLASS'
    TABLE_CHOOSE: RailsAdmin.TableConcept

  document_on: => [
    'click', @LINK, (event, target) =>
      return if (@link_wrapper = target).has_disabled()

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

  #### PRIVATE ####

  prepend_old_list_and_replace_container: (data) =>
    index = $("<div>").html(data)
    new_container = index.find(@CONTAINER)
    if (new_list = new_container.find('tbody:last > tr:first')).length
      $(@TABLE_CHOOSE).remove()
      new_list.prepend($('tbody:last').html())
      new_list.find('tr:last').addClass(@SEPARATOR_CLASS)
      $(@CONTAINER).html(new_container.html())
    else
      $(@LINK).add_disabled()
