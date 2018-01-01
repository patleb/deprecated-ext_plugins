Array.define_methods
  is_a: (klass) ->
    _.isArray(klass::)

  to_a: ->
    this

  to_s: ->
    this.toString()

  blank: ->
    _.isEmpty(this)

  present: ->
    !this.blank()

  presence: ->
    this unless this.blank()

  empty: ->
    _.isEmpty(this)

  index: (object, start_index = 0) ->
    if (index = this.indexOf(object, start_index)) != -1
      index

  any: (f_item_index_self_or_keys) ->
    if f_item_index_self_or_keys?
      _.some(this, f_item_index_self_or_keys)
    else
      this.length > 0

  all: (f_item_index_self_or_keys) ->
    _.every(this, f_item_index_self_or_keys)

  includes: (object, start_index = 0) ->
    _.includes(this, object, start_index)

  excludes: (object, start_index = 0) ->
    !this.includes(object, start_index)

  each: (f_item_index_self) ->
    _.forEach this, f_item_index_self

  each_with_object: (f_item_memo_index_self, accumulator) ->
    f = (memo, item, index, self) ->
      f_item_memo_index_self(item, memo, index, self)
      accumulator
    _.reduce(this, f, accumulator)

  each_slice: (size = 1) ->
    _.chunk(this, size)

  sort_by: (f_item_or_keys...) ->
    _.sortBy(this, f_item_or_keys.unsplat())

  select: (f_item_index_self_or_keys) ->
    _.filter(this, f_item_index_self_or_keys)

  reject: (f_item_index_self_or_keys) ->
    _.reject(this, f_item_index_self_or_keys)

  except: (objects...) ->
    _.without(this, objects.unsplat()...)

  compact: ->
    this.select (item) -> item?

  delete: (objects...) ->
    _.pull(this, objects.unsplat()...)

  delete_if: (f_item) ->
    _.remove(this, f_item)

  dup: ->
    _.clone(this)

  deep_dup: ->
    _.cloneDeep(this)

  first: ->
    this[0]

  last: ->
    this[this.length - 1]

  html_map: (f_item_index_self) ->
    html(this.map(f_item_index_self))

  flatten: ->
    _.flattenDeep(this)

  union: (other_arrays...) ->
    _.union this, other_arrays...

  unsplat: ->
    if this[0]?.is_a(Array)
      this[0]
    else
      this

  extract_options: ->
    if this.last()?.is_a(Object)
      this.pop()
    else
      {}

Array.decorate_methods
  find: (f_item_index_self_or_keys) ->
    if arguments.length == 1
      _.find(this, f_item_index_self_or_keys)
    else
      this.super.apply(this, arguments)
