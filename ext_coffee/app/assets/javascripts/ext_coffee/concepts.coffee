self = this

class Js.Concepts
  life_cycle = {
    ready_once: []
    leave: []
    ready_first: []
    ready: []
    ready_last: []
  }
  uniq_methods = []
  uniq_concepts = {}
  initialized = false

  @initialize: (options = {}) =>
    if initialized
      return Logger.debug('Js.Concepts already initialized')
    initialized = true

    modules = options.modules || []
    concepts = options.concepts || []
    modules.each (module_name) =>
      module_name.constantize().each (concept_name) =>
        @add_concept(concept_name, module_name)
    concepts.each (concept_name) =>
      @add_concept(concept_name)

    # necessary for having accurate jQuery heights/widths
    retries = 0
    test = setInterval(->
      if $("head > link[href$='.css']").last().prop('sheet')?.cssRules.length || retries >= 50
        Logger.debug("CSS load #{retries * 20} ms")
        clearInterval(test)
        setTimeout(->
          $(document).ready (args...) ->
            while life_cycle.ready_once.length
              life_cycle.ready_once.shift().ready_once(args...)
            if $(document.body).has_once()
              life_cycle.leave.each (concept) ->
                concept.leave(args...)
            else
              $(document.body).add_once()
            life_cycle.ready_first.each (concept) ->
              concept.ready_first(args...)
            life_cycle.ready.each (concept) ->
              concept.ready(args...)
            life_cycle.ready_last.each (concept) ->
              concept.ready_last(args...)
        , 80)
      else
        retries++
    , 20)

  @add_concept: (concept_name, module_name = null) =>
    return unless /Concept$/.match(concept_name)

    concept_name = "#{module_name}.#{concept_name}" if module_name?
    names = concept_name.split('.')
    module_name ||= (names.length && names[0..-2].join('.')) || ''
    class_name = names.last()

    if uniq_concepts[class_name]
      return Logger.debug("Concept #{class_name} already defined")
    uniq_concepts[class_name] = true

    concept_class = concept_name.constantize()
    concept_class::module_name = module_name
    concept_class::class_name = class_name

    constants = concept_class::constants?().each_with_object (name, value, constants) =>
      @define_constant(concept_class, name, value, constants)
    , {}
    concept_class::constants = constants || {}

    module_class = module_name.constantize()
    module_class[class_name] = concept = new concept_class

    if concept.document_on? && uniq_methods.excludes(concept_class::document_on)
      uniq_methods.push(concept_class::document_on)
      @define_document_on(concept)

    if concept.global
      global_name = class_name.sub(/Concept$/, '')
      Logger.warn_define_singleton_method(self, global_name)
      self[global_name] = concept

    life_cycle.each (phase, all) ->
      if concept[phase]? && uniq_methods.excludes(concept_class::[phase])
        uniq_methods.push(concept_class::[phase])
        all.push(concept)

    concept_class::select((name) -> /Element$/.match(name)).each (name, klass) =>
      @add_element(name, klass, concept)

  #### PRIVATE ####

  @add_element: (element_name, element_class, concept) =>
    element_class::c = concept
    element_class.class_name = element_class::class_name = element_name

    concept.constants.each (name, value) ->
      element_class::[name] = value
    constants = element_class::constants?().each_with_object (name, value, constants) =>
      @define_constant(element_class, name, value, constants)
    , {}
    element_class::constants = constants || {}

    if element_class::document_on? && uniq_methods.excludes(element_class::document_on)
      uniq_methods.push(element_class::document_on)
      @define_document_on(element_class::)

    attr_readers = element_class::attr_readers?().each_with_object (name, value, readers) =>
      element_class::[name] = -> this["__#{name}"] ?= value.apply(this, arguments)
      readers.push(name)
    , []
    element_class::attr_readers = attr_readers || []

  @define_constant: (klass, name, value, constants) =>
    if value.class_name
      scope = value.class_name
      scope = value::c.class_name if scope == 'Element'
      prefix = scope.sub(/(Concept|Element)$/, '').underscore().upcase()
      shared = name.sub(///#{prefix}_///, '')
      value = if value::?.c then value::[shared] else value[shared]
    else if value.is_a(Function)
      return @define_constant(klass, name, value(), constants)

    if ['', 'ID', 'CLASS', 'FIRST', 'LAST'].includes(value)
      scope = klass::class_name
      scope = klass::c.class_name if scope == 'Element'
      scope = scope.sub(/(Concept|Element)$/, '')
      prefixes = @isolate(klass)
      scope = prefixes.concat(scope).join('_') if prefixes.any()
      type = value
      value = "js_#{scope.underscore()}_#{name.downcase()}"
      switch type
        when 'ID'
          constants[name] = klass::[name] = "##{value}"
          name = "#{name}_ID"
        when 'CLASS'
          constants[name] = klass::[name] = ".#{value}"
          name = "#{name}_CLASS"
        when 'FIRST', 'LAST'
          constants[name] = klass::[name] = ".#{value}:#{type.downcase()}"
          name = "#{name}_CLASS"

    constants[name] = klass::[name] = value

  @define_document_on: (object) ->
    document_on_before = if object.document_on_before? && uniq_methods.excludes(object.document_on_before)
      uniq_methods.push(object.document_on_before)
      object.document_on_before
    document_on_after = if object.document_on_after? && uniq_methods.excludes(object.document_on_after)
      uniq_methods.push(object.document_on_after)
      object.document_on_after

    object.document_on().each_slice(3).each ([events, selector, handler]) ->
      with_target = handler
      handler = (event) ->
        event.preventDefault() if events.includes('click') && events.excludes('.continue')
        target = $(event.currentTarget)
        args = Array.prototype.slice.call(arguments)
        args.push(target)
        with_target.apply(this, args)
      if document_on_before
        with_before = handler
        handler = ->
          result = document_on_before.apply(this, arguments)
          unless result == Js.ABORT
            result = with_before.apply(this, arguments)
          result
      if document_on_after
        uniq_methods.push(object.document_on_after)
        with_after = handler
        handler = ->
          result = with_after.apply(this, arguments)
          unless result == Js.ABORT
            document_on_after.apply(this, arguments)

      $(document).on events, selector, handler

  @isolate: (klass) ->
    prefixes = []
    module_name = (klass::c || klass::).module_name
    if (isolate = module_name.constantize().isolate)
      switch isolate
        when  true  then prefixes.push module_name.acronym()
        when 'full' then prefixes.push module_name
        else             prefixes.push isolate.camelize()
    if (isolate = klass::c?.isolate)
      switch isolate
        when  true  then prefixes.push klass::c.class_name.acronym().chop()
        when 'full' then prefixes.push klass::c.class_name.sub(/Concept$/, '')
        else             prefixes.push isolate.camelize()
    prefixes
