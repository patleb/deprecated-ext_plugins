Boolean.define_methods
  is_a: (klass) ->
    _.isBoolean(klass::)

  to_b: ->
    this.valueOf()

  to_i: ->
    if this.valueOf() then 1 else 0

  to_s: ->
    this.toString()

  blank: ->
    !this.valueOf()

  present: ->
    this.valueOf()

  presence: ->
    this.valueOf() if this.valueOf()

  safe_text: ->
    this.toString()

  html_safe: ->
    true
