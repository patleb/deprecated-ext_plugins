class Js.TimeZoneConcept
  global: true

  ready_once: =>
    old_Intl = window.Intl
    @timezone =
      try
        window.Intl = undefined
        tz = jstz.determine().name()
        window.Intl = old_Intl
        tz
      catch e
        # sometimes (on android) you can't override intl
        jstz.determine().name()

    Cookies.set("js.time_zone", @timezone, secure: (window.location.protocol == 'https:'))

  name: =>
    @timezone
