RegExp.define_methods
  is_a: (klass) ->
    klass == RegExp

  blank: ->
    false

  present: ->
    true

  presence: ->
    this

  match: (str) ->
    str.match(this)
