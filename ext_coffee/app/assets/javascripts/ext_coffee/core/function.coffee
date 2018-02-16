JS_CONCEPTS_METHODS = [
  'ready_once'
  'leave'
  'ready_first'
  'ready'
  'ready_last'
  'module_name'
  'c'
  'class_name'
  'constants'
  'accessors'
  'document_on_before'
  'document_on'
  'document_on_after'
  'global'
  'isolate'
]

PROTECTED_METHODS = [
  'included'
  'extended'
].concat(JS_CONCEPTS_METHODS)

Function.define_singleton_methods
  delegate_to: (receiver, base, keys...) ->
    { closure, resolve, anchor, force, prefix } = keys.extract_options()
    prefix ||= ''
    if anchor
      anchor_name = if anchor.is_a(String) then "_anchor".prefix_of(anchor) else '_anchor'
      receiver[anchor_name] ?= base
    keys = keys.unsplat()
    keys = base.keys() if keys.empty()
    keys.except(PROTECTED_METHODS unless force).each (key) ->
      if force || !key.starts_with('_') # skip private
        prefixed_key = prefix.prefix_of(key)
        if !closure && !resolve
          receiver[prefixed_key] = if anchor then receiver[anchor_name][key] else base[key]
        else if closure && !resolve
          receiver[prefixed_key] = if anchor then -> receiver[anchor_name][key] else -> base[key]
        else if !closure && resolve
          receiver[prefixed_key] = if anchor then receiver[anchor_name][key]() else base[key]()
        else
          receiver[prefixed_key] = if anchor then -> receiver[anchor_name][key]() else -> base[key]()
    receiver

Function.define_methods
  is_a: (klass) ->
    _.isFunction(klass::) && klass != jQuery

  blank: ->
    false

  present: ->
    true

  presence: ->
    this

  include: (base, keys...) ->
    Function.delegate_to this.prototype, base.prototype, keys...
    base.included?(this.prototype)

  extend: (base, keys...) ->
    Function.delegate_to this, base, keys...
    base.extended?(this)
