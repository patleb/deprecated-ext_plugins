class RailsAdmin.FieldConcept
  constants: =>
    INPUT: 'CLASS'
    FIELDS: => "#{@INPUT}:not(.#{$.ONCE})"

  ready: ({ scoped = false } = {}) =>
    return unless (fields = $(@FIELDS)).length

    unscoped_fields = if scoped then @fields || {} else {}
    @fields = fields.each_with_object (input, memo) =>
      input.add_once()
      input_classes = input.classes()
      element_index = input_classes.index(@INPUT_CLASS) + 1 # Next class is the element name
      element_name = input_classes[element_index].sub(/^js_/, '').camelize()
      memo[input.attr('id')] = new @["#{element_name}Element"](input)
    , unscoped_fields
