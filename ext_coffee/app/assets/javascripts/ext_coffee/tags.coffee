class Js.Tags
  @HTML_TAGS: [
    'a'
    'b'
    'button'
    'dd'
    'div'
    'dl'
    'dt'
    'fieldset'
    'h1'
    'h2'
    'h3'
    'h4'
    'h5'
    'h6'
    'hr'
    'i'
    'input'
    'label'
    'legend'
    'li'
    'option'
    'p'
    'table'
    'tbody'
    'td'
    'th'
    'thead'
    'tr'
    'select'
    'span'
    'ul'
  ] # TODO allow adding tags like in ext_rails
  ID_CLASSES = /^[\.#][^\.#]/

  @initialize: (context) =>
    Logger.warn_define_singleton_method(context, 'html')
    context.html = @html
    @HTML_TAGS.each (tag) =>
      Logger.warn_define_singleton_method(context, tag)
      context[tag] = (args...) =>
        @with_tag(tag, args...)

  #### PRIVATE ####

  @html: (values...) ->
    values = values.flatten()
    all_ok = values.all (item) -> item.html_safe()
    values = values.join('')
    values.html_safe(all_ok)

  @with_tag: (tag, [id_classes_or_text, text_or_options, options, block]...) =>
    if id_classes_or_text?.is_a(String)
      if text_or_options?.is_a(Object)
        [text_or_options, options, block] = [null, text_or_options, options]
      else if text_or_options?.is_a(Function)
        [text_or_options, options, block] = [null, null, text_or_options]
    else if id_classes_or_text?.is_a(Object)
      [id_classes_or_text, text_or_options, options, block] = [null, null, id_classes_or_text, text_or_options]
    else
      [id_classes_or_text, text_or_options, options, block] = [null, null, null, id_classes_or_text]

    options ?= {}
    escape = options.delete('escape') ? true
    if id_classes_or_text?
      if id_classes_or_text.is_a(String)
        if id_classes_or_text.match(ID_CLASSES)
          [id, classes] = @parse_id_classes(id_classes_or_text)
          options.id ||= id
          options = @merge_classes(options, classes)
          text = text_or_options
        else
          text = id_classes_or_text
      else if id_classes_or_text.is_a(Array)
        text = id_classes_or_text
      else
        text = text_or_options
    else
      text = text_or_options

    text = options.delete('text') if options.text?
    text = block() if !text? && block?
    text = @html(text) if text?.is_a(Array)

    @content_tag(tag, text || '', options, escape)

  @parse_id_classes: (string) ->
    [classes, _separator, id_classes] = string.partition('#')
    classes = classes.split('.')
    if id_classes
      [id, other_classes...] = id_classes.split('.')
      classes = classes.concat(other_classes)
    [id, classes]

  @merge_classes: (options, classes) =>
    if options.has_key('class')
      options.merge class: classes, (old_val, new_val, key) =>
        if key == 'class'
          old_array = @classes_to_array(old_val)
          new_array = @classes_to_array(new_val)
          old_array.union(new_array)
    else
      options.class = @classes_to_array(classes)
      options

  @classes_to_array: (classes) ->
    if classes?.is_a(Array)
      classes
    else
      classes?.split(' ') || []

  @content_tag: (tag, text, options, escape) =>
    if options.class?.is_a(Array)
      options.class = options.class.select((item) -> item?.present()).join(' ')
      options.delete('class') if options.class.blank()
    if options.data?.is_a(Object)
      { data: options.delete('data') }.flatten('-').each (key, value) ->
        options[key] = value
    tag = $("<#{tag}>", options)
    if escape && !text.html_safe()
      tag.text(text.safe_text())
    else
      tag.html(text)
    tag.to_s().html_safe(true)

Js.Tags.initialize(this)
