Number.define_methods
  is_a: (klass) ->
    _.isNumber(klass::)

  to_b: ->
    return true if this == 1
    return false if this == 0
    throw "invalid value for Boolean: '#{this}'"

  to_i: ->
    this.valueOf()

  to_s: ->
    this.toString()

  blank: ->
    isNaN(this)

  present: ->
    !this.blank()

  presence: ->
    this.valueOf() unless this.blank()

  safe_text: ->
    this.toString()

  html_safe: ->
    true
