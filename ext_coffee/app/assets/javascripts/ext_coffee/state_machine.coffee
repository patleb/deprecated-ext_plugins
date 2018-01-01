###
# Example
@sm = new Js.StateMachine 'state_machine_id', {
  initialize: (sm, reset_arg) ->  # reset_arg used only when calling 'reset(arg)'
    'do stuff'
  before: (sm, arg) ->            # run before each transition and 'stop()'/'defer()' could be used
    'do stuff'
  after: (sm, arg) ->             # run before each transition
    'do stuff'
  rescue: (sm, arg) ->            # run only if the transition is denied by an undefined transition
    'do stuff'
  initial: 'rolling'              # *mandatory (could be a callback as well which is evaluated on initialize/reset)
  flags: true                     # extract implicit boolean 'flags', all the states need to have a name with the flags separated by a dash, ex.: 'rolling-with_class'
  triggers:                       # *mandatory
    park:
      rolling: 'parked'           # from => to
      moving: 'parked'
# or
      '*': 'parked'               # TODO test: from 'any state' to 'parked'
# or
      from: 'rolling'
# or
      from: '*'
# or
      from: ['rolling', 'moving']
# or
      from: ['*', 'parked']       # from 'any state' except 'parked'
      to: 'parked'                # same arg as the short syntax 'from => to'
      if: (sm, arg) ->            # run the transition only if the 'predicate' is truthy
        'test stuff'
      skip_before: true           # skip the generic 'before' hook
      skip_after: true            # skip the generic 'after' hook
      before: (sm, arg) ->        # run before the 'transition' and 'stop()'/'defer()' could be used
        'do stuff'
      after: (sm, arg) ->         # run after the 'transition'
        'do stuff'
  states:                         # configure each state by assigning hooks and associated immuatable data (could be used to manually set boolean flags)
    rolling:
      skip_before: true           # skip the generic 'before' hook
      skip_after: true            # skip the generic 'after' hook
      exit: (sm, arg) ->          # run before the 'transition' and 'stop()'/'defer()' could be used
        'do stuff'
      enter: (sm, arg) ->         # run after the 'transition'
        'do stuff'
    moving:
      on_road: true
      in_parking: false
      title: 'Moving'
    parked:
      on_road: false
      in_parking: true
      title: 'Parked'
}
###

class Js.StateMachine
  SETTINGS = [
    'initial'
    'flags'
    'initialize'
    'before'
    'after'
    'rescue'
    'triggers'
    'states'
  ]
  TRIGGER_HOOKS = ['if', 'skip_before', 'skip_after', 'before', 'after']
  STATE_HOOKS = ['skip_before', 'skip_after', 'exit', 'enter']
  WILDCARD = '*'
  STATUS = {
    HALTED: 'HALTED'
    DENIED: 'DENIED'
    SKIPPED: 'SKIPPED'
    CHANGED: 'CHANGED'
  }

  constructor: (@name, @settings) ->
    @initial = @settings.initial
    ['initialize', 'before', 'after', 'rescue'].each (hook) =>
      @[hook] = @settings[hook] || ->
    @extract_triggers_states_transitions()
    @extract_flags() if @settings.flags
    @reset()

  current: =>
    @state

  data: =>
    @states[@current()].data

  is: (state) =>
    if state.is_a(RegExp)
      !!@current().match(state)
    else
      @current() == state

  can: (trigger) =>
    @get_transition(trigger)?

  has_stopped: =>
    @stopped

  stop: =>
    @stopped = true

  resume: =>
    @stopped = false

  has_deferred: =>
    @deferred

  defer: =>
    @deferred = true

  resolve: (arg) =>
    return unless @deferred
    @deferred = false
    @set_next_state()
    @run_after_hooks(arg)

  reject: =>
    @deferred = false

  reset: (arg) =>
    if @initial.is_a(Function)
      @state = @initial(this)
    else
      @state = @initial
    @stopped = false
    @deferred = false
    @initialize(this, arg)
    @log_initialized()

  trigger: (trigger, arg) =>
    @triggers[trigger](arg)

  #### PRIVATE ####

  run_trigger: (trigger, arg) =>
    if @skip_transition()
      return STATUS.HALTED

    unless @can(trigger)
      @rescue(this, arg)
      @log_denied(trigger)
      return STATUS.DENIED

    @set_transition(trigger)
    if @transition.unless(this, arg) && !@transition.if(this, arg)
      return STATUS.SKIPPED

    @run_before_hooks(arg)
    if @skip_transition()
      @log_halted()
      return STATUS.HALTED

    @set_next_state()
    @log_changed()
    @run_after_hooks(arg)
    STATUS.CHANGED

  run_before_hooks: (arg) =>
    from_state = @states[@transition.from].hooks
    unless @transition.skip_before || from_state.skip_before
      @before(this, arg)
    @transition.before(this, arg) unless @skip_transition()
    from_state.exit(this, arg) unless @skip_transition()

  run_after_hooks: (arg) =>
    to_state = @states[@transition.to].hooks
    to_state.enter(this, arg)
    unless @transition.skip_after || to_state.skip_after
      @after(this, arg)
    @transition.after(this, arg)

  skip_transition: =>
    @has_stopped() || @has_deferred()

  get_transition: (trigger) =>
    @transitions[trigger][@state]

  set_transition: (trigger) =>
    @transition = @get_transition(trigger)

  set_next_state: =>
    @state = @transition.to

  extract_triggers_states_transitions: =>
    @triggers = {}
    @states = {}
    @transitions = {}
    wildcards = {}
    @settings.triggers.each (trigger, trigger_settings) =>
      from_state = trigger_settings.from
      hooks = trigger_settings.slice(TRIGGER_HOOKS)
      if from_state?
        if from_state.includes(WILDCARD)
          wildcards[trigger] = trigger_settings
          return
        next_state = trigger_settings.to
        if from_state.is_a(Array)
          from_state.each (previous_state) =>
            @add_trigger_state_transition(trigger, previous_state, next_state, hooks)
        else
          @add_trigger_state_transition(trigger, from_state, next_state, hooks)
      else
        transitions = trigger_settings.except(TRIGGER_HOOKS)
        transitions.each (from_state, next_state) =>
          if from_state == WILDCARD
            wildcards[trigger] = trigger_settings
            @add_default_state(next_state)
          else
            @add_trigger_state_transition(trigger, from_state, next_state, hooks)
    @configure_states(wildcards)
    @add_wildards(wildcards)

  configure_states: (wildcards) =>
    if @initial?.is_a(String)
      @add_default_state(@initial)
    (@settings.states || {}).each (state_name, state_settings) =>
      @add_default_state(state_name)
      state_settings.slice(STATE_HOOKS).each (hook_name, hook) =>
        @states[state_name].hooks[hook_name] = hook
      @states[state_name].data = state_settings.except(STATE_HOOKS)

  add_wildards: (wildcards) =>
    wildcards.each (trigger, trigger_settings) =>
      hooks = trigger_settings.slice(TRIGGER_HOOKS)
      from_state = trigger_settings.from
      if from_state?
        next_state = trigger_settings.to
      else
        transitions = trigger_settings.except(TRIGGER_HOOKS)
        from_state = (WILDCARD if (next_state = transitions[WILDCARD]))
      except_states = if from_state?.is_a(Array) then from_state.except(WILDCARD) else []
      except_states.each (state) =>
        @add_default_state(state)
      @states.keys().except(except_states).each (previous_state) =>
        @add_trigger_state_transition(trigger, previous_state, next_state, hooks)

  add_trigger_state_transition: (trigger, from, to, hooks) =>
    [from, to].each (state) =>
      @add_default_state(state)
    @triggers[trigger] = (arg) => @run_trigger(trigger, arg)
    @add_transition(trigger, from, to, hooks)

  add_default_state: (state) =>
    @states[state] ?= {
      hooks: {
        skip_before: false
        skip_after: false
        exit: ->
        enter: ->
      }
      data: {}
    }

  add_transition: (trigger, from, to, hooks) =>
    @transitions[trigger] ?= {}
    @transitions[trigger][from] = {
      trigger: trigger
      from: from
      to: to
      if: hooks.if || -> true
      unless: hooks.unless || -> false
      skip_before: hooks.skip_before || false
      skip_after: hooks.skip_after || false
      before: hooks.before || ->
      after: hooks.after || ->
    }

  extract_flags: =>
    flags = {}
    @states.each (name, _empty_hash) ->
      name.split('-').each ([flag, index]) ->
        flags[index] ?= {}
        flags[index][flag] = true
    @states.each (name, _empty_hash) =>
      name.split('-').each ([flag, index]) =>
        flags[index].keys().each (index_flag) =>
          @states[name].data[index_flag] = index_flag == flag

  log_initialized: =>
    Logger.debug_state_machine "[SM_INITIALIZED][#{@name}] #{@state}"
  log_denied: (trigger) =>
    Logger.debug_state_machine "[SM_DENIED]     [#{@name}][#{trigger}] #{@state}"
  log_halted: =>
    Logger.debug_state_machine "[SM_HALTED]     [#{@name}][#{@transition.trigger}] #{@state} => #{@transition.to}"
  log_changed: =>
    Logger.debug_state_machine "[SM_CHANGED]    [#{@name}][#{@transition.trigger}] #{@transition.from} => #{@state}"
