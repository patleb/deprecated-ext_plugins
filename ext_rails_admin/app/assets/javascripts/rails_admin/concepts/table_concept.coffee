# TODO https://makandracards.com/makandra/24451-sticky-table-header-with-jquery

class RailsAdmin.TableConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    WRAPPER: 'CLASS'
    STICKY_HEAD: 'CLASS'
    SCROLL_UP: 'CLASS'
    SCROLL_X: 'CLASS'
    APPLICATION_WINDOW: RailsAdmin.ApplicationConcept

  document_on: => [
    'click', @SCROLL_UP, =>
      $('html, body').animate(scrollTop: 0)
      $(@APPLICATION_WINDOW).animate(scrollTop: 0)

    'click', @SCROLL_X, =>
      wrapper = $(@WRAPPER)
      scroll_width = (wrapper[0].scrollWidth - wrapper[0].clientWidth)
      if wrapper.scrollLeft() < scroll_width / 2
        wrapper.animate(scrollLeft: scroll_width)
      else
        wrapper.animate(scrollLeft: 0)
  ]

  ready: =>
    return unless (@table_wrapper = $(@WRAPPER)).length

    @table = @table_wrapper.find('.table')
    @table_head = @table.find('thead')
    @sticky_head = $(@STICKY_HEAD)
    @sticky_table = @sticky_head.find('.table')

    @bind_sticky_head()
    @bind_double_scroll()
    @bind_scroll_x()
    @update_sticky_head()
    @toggle_scroll_x()

  leave: =>
    @unbind_sticky_head()

  #### PRIVATE ####

  bind_sticky_head: =>
    $(@APPLICATION_WINDOW).on 'scroll.table_concept', _.throttle(@toggle_sticky_head, 100)
    $(window).on 'scroll.table_concept', _.throttle(@toggle_sticky_head, 100)
    $(window).on 'resize.table_concept', _.throttle(@update_sticky_head, 100)

  unbind_sticky_head: =>
    $(@APPLICATION_WINDOW).off 'scroll.table_concept'
    $(window).off 'scroll.table_concept'
    $(window).off 'resize.table_concept'

  bind_double_scroll: =>
    # https://github.com/cubiq/iscroll
    if Device.touched
      @table_wrapper.on 'touchmove', =>
        @sticky_table[0].style.left = "-#{@table_wrapper.scrollLeft()}px"
    else
      @table_wrapper.on 'scroll', =>
        @sticky_table[0].style.left = "-#{@table_wrapper.scrollLeft()}px"

  bind_scroll_x: =>
    $(window).on 'resize.table_concept', _.throttle(@toggle_scroll_x, 100)

  update_sticky_head: =>
    @sticky_head.css(width: "#{@table_wrapper[0].scrollWidth}px")
    sticky_head_row = @sticky_head.find('.table > thead > tr:first > th')
    @table_head.find('tr:first > th').each (index) ->
      width = $(this).outerWidth()
      $(sticky_head_row[index]).css(width: width)
    @toggle_sticky_head()

  toggle_sticky_head: =>
    if @table_wrapper.offset().top < $(window).scrollTop()
      @sticky_head.show()
      @table_head.fadeTo(0, 0)
    else
      @sticky_head.hide()
      @table_head.fadeTo(0, 1)

  toggle_scroll_x: =>
    if $(@WRAPPER).has_scroll_x()
      $(@SCROLL_X).show()
    else
      $(@SCROLL_X).hide()
