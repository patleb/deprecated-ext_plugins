class Js.I18nConcept
  global: true

  constants: ->
    TRANSLATIONS: 'ID'

  ready_once: =>
    @locale = $('html').attr('lang') || 'en'
    @translations = $(@TRANSLATIONS).data('js')
    moment.locale(@locale)

  t: (key) =>
    @filter_exceptions(@translations[key]) || key.humanize()

  #### PRIVATE ####

  filter_exceptions: (value) ->
    switch value
      when true
        'True'
      else
        value
