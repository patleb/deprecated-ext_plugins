class RailsAdmin.TableConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    WRAPPER: 'CLASS'
    STICKY_HEAD: 'CLASS'
    APPLICATION_WINDOW: RailsAdmin.ApplicationConcept

  ready: =>
    return unless (@table_wrapper = $(@WRAPPER)).length

    @table = @table_wrapper.find('.table')
    @table_head = @table.find('thead')
    @sticky_head = $(@STICKY_HEAD)
    @sticky_table = @sticky_head.find('.table')

    @bind_sticky_head()
    @bind_double_scroll()
    @update_sticky_head()

  leave: =>
    @unbind_sticky_head()

  #### PRIVATE ####

  bind_sticky_head: =>
    $(@APPLICATION_WINDOW).on 'scroll.responsive_table', _.throttle(@toggle_sticky_head, 100)
    $(window).on 'scroll.responsive_table', _.throttle(@toggle_sticky_head, 100)
    $(window).on 'resize.responsive_table', _.throttle(@update_sticky_head, 100)

  unbind_sticky_head: =>
    $(@APPLICATION_WINDOW).off 'scroll.responsive_table'
    $(window).off 'scroll.responsive_table'
    $(window).off 'resize.responsive_table'

  bind_double_scroll: =>
    @table_wrapper.on 'scroll', (event) =>
      @sticky_table.css(left: "-#{@table_wrapper.scrollLeft()}px")

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
