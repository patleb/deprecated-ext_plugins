# TODO simulate mouse swipe/drag like with a mac mouse instead

class RailsAdmin.DoubleScrollConcept
  WRAPPER: '.js_double_scroll_wrapper'

  ready: =>
    wrappers = $(@WRAPPER)
    wrappers.on 'scroll', _.throttle((event) ->
      $(this).next().scrollLeft($(this).scrollLeft())
    , 10)

    @containers = wrappers.next()
    @containers.on 'scroll', _.throttle((event) ->
      $(this).prev().scrollLeft($(this).scrollLeft())
    , 10)

    setTimeout(@toggle_bars, 10)
    $(window).on 'resize.double_scroll', _.throttle(@toggle_bars, 100)

  leave: ->
    $(window).off('resize.double_scroll')

  #### PRIVATE ####

  toggle_bars: =>
    @containers.each (container) ->
      container = $(container)

      visible_bottom = container.offset().top + container.height() <= document.documentElement.clientHeight
      if container[0].scrollWidth <= container.width() || visible_bottom
        container.prev().hide()
      else
        container.prev().show()

      content = container.find('>:first-child')
      wrapper = container.prev()
      scroll_bar = wrapper.find('.scroll_bar')
      scroll_bar.width(content.outerWidth())
      wrapper.width(container.width())
      wrapper.scrollLeft(container.scrollLeft())
