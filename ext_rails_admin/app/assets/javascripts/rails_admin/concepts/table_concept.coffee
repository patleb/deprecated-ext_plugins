# TODO https://makandracards.com/makandra/24451-sticky-table-header-with-jquery

class RailsAdmin.TableConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    WRAPPER: 'CLASS'
    HEADER: 'CLASS'
    STICKY_HEAD: 'CLASS'
    SCROLL_UP: 'CLASS'
    SCROLL_X: 'CLASS'
    CHOOSE: 'CLASS'
    REMOVE_COLUMN: 'CLASS'
    RESTORE_COLUMNS: 'CLASS'
    REMOVED_COLUMNS: 'ID'
    APPLICATION_WINDOW: RailsAdmin.ApplicationConcept

  document_on: => [
    'click', @SCROLL_UP, =>
      $('html, body').animate(scrollTop: 0)
      $(@APPLICATION_WINDOW).animate(scrollTop: 0)

    'click', @SCROLL_X, =>
      scroll_width = (@table_wrapper[0].scrollWidth - @table_wrapper[0].clientWidth)
      if @table_wrapper.scrollLeft() < scroll_width / 2
        @table_wrapper.animate(scrollLeft: scroll_width)
      else
        @table_wrapper.animate(scrollLeft: 0)

    'click', @REMOVE_COLUMN, (event, target) =>
      name = target.data('js')
      $(".#{name}_field").remove()
      @update_sticky_head()
      @save_column(name)

    'click', @RESTORE_COLUMNS, =>
      Cookie.remove(@cookie_key())
      $.pjax.reload()
  ]

  ready: =>
    return unless (@table_wrapper = $(@WRAPPER)).length

    @table = @table_wrapper.find('.table')
    @table_head = @table.find('thead')
    @sticky_head = $(@STICKY_HEAD)
    @sticky_table = @sticky_head.find('.table')
    @scroll_x = $(@SCROLL_X)

    $(@APPLICATION_WINDOW).on 'scroll.table_concept', _.throttle(@on_window_scroll, 100)
    $(window).on 'scroll.table_concept', _.throttle(@on_window_scroll, 100)
    $(window).on 'resize.table_concept', _.throttle(@on_window_resize, 100)

    # https://github.com/cubiq/iscroll
    @table_wrapper.on 'scroll', =>
      @sticky_table.css(left: "-#{@table_wrapper.scrollLeft()}px")

    @update_sticky_head()
    @toggle_scroll_x()

  leave: =>
    $(@APPLICATION_WINDOW).off 'scroll.table_concept'
    $(window).off 'scroll.table_concept'
    $(window).off 'resize.table_concept'

  #### PRIVATE ####

  on_window_scroll: =>
    @toggle_sticky_head()
    @toggle_scroll_x()

  on_window_resize: =>
    @update_sticky_head()
    @toggle_scroll_x()

  update_sticky_head: =>
    @sticky_head.css(width: "#{@table_wrapper.outerWidth()}px")
    sticky_head_row = @sticky_head.find('.table > thead > tr:first > th')
    @table_head.find('tr:first > th').a_each (th, i) =>
      column = $(sticky_head_row[i])
      column.css(width: "#{th.outerWidth()}px")
      if th.classes().includes('header')
        column.addClass(@HEADER_CLASS)
    @toggle_sticky_head()

  toggle_sticky_head: =>
    if @table_wrapper.offset().top < $(window).scrollTop()
      @sticky_head.show()
      @table_head.fadeTo(0, 0)
    else
      @sticky_head.hide()
      @table_head.fadeTo(0, 1)

  toggle_scroll_x: =>
    if @table_wrapper.has_scroll_x() && @not_at_bottom()
      @scroll_x.css(visibility: 'visible')
    else
      @scroll_x.css(visibility: 'hidden')

  not_at_bottom: =>
    table_bottom = @table_wrapper.offset().top + @table_wrapper.height()
    scroll_x_bottom = @scroll_x.offset().top + @scroll_x.height()
    table_bottom >= scroll_x_bottom + 34

  save_column: (name) =>
    key = @cookie_key()
    list = (Cookie.get(key) || '{}').to_json()
    list[name] = 1
    Cookie.set(key, list)

  cookie_key: =>
    "#{@abstract_model()}.list"
