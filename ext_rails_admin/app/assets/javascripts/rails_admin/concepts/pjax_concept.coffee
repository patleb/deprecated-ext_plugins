class RailsAdmin.PjaxConcept
  @include RailsAdmin.ApplicationConcept

  constants: ->
    APPLICATION_WINDOW: RailsAdmin.ApplicationConcept
    APPLICATION_TITLE: RailsAdmin.ApplicationConcept
    PJAX_TITLE: Js.Pjax.TITLE

  constructor: ->
    Js.Pjax.initialize(scroll_wrapper: @APPLICATION_WINDOW)

  document_on: => [
    'click.continue', '.pjax', (event) =>
      $.pjax.click(event,
        active_wrapper: '.nav.nav-pills li.active'
        active_exclude: [User.edit_path()]
      )
  ]

  ready: =>
    $('.nav.nav-pills li.active').removeClass('active')
    $(".nav.nav-pills li[data-model='#{@abstract_model()}']").addClass('active')
    $(@APPLICATION_TITLE).text($(@PJAX_TITLE).data('js'))
