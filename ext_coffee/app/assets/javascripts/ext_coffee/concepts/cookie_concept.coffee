class Js.CookieConcept
  global: true

  set: (key, value = true) ->
    Cookies.set("js.#{key}", value, secure: (window.location.protocol == 'https:'))

  get: (key) ->
    Cookies.get("js.#{key}")

  remove: (key) ->
    Cookies.remove("js.#{key}")
