#= require rails_admin/concepts/filter_box_concept

# https://github.com/chartjs/Chart.js/issues/5106 --> wait version 2.8
class RailsAdmin.ChartConcept
  constants: ->
    CONFIG: '.js_chartkick_config'
    CHART_ID: 'chart-1'
    INIT: 'ID'
    ADDED_LIST: 'CLASS'
    ADDED_ITEM: 'CLASS'
    ADD_LINK: 'CLASS'
    FORM: 'CLASS'
    INPUTS: 'CLASS'
    SUBMIT_BUTTON: 'CLASS'
    FILTER_BOX_FORM: RailsAdmin.FilterBoxConcept

  document_on: => [
    'click', @ADD_LINK, (event) =>
      options = @current_item()
      @append_item(options)

    'click', "#{@ADDED_ITEM} .delete", (event, target) =>
      item = target.closest(@ADDED_ITEM)
      @remove_item(item)

    'keydown', '#chart_action > form', (event) =>
      if event.which == $.ui.keyCode.ENTER
        event.preventDefault()
        $(@SUBMIT_BUTTON).click()
  ]

  ready: =>
    # necessary since index action is used for rendering chart view
    if $('#chart_action').length
      $('.index_collection_link').removeClass('active')
      $('.chart_collection_link').addClass('active')

    @charts = $(@CONFIG).each_with_object {}, (chart, result) ->
      config = chart.data('js')
      result[config.id] = new Chartkick[config.type](config.id, config.source, config.options)

    ordered_charts = $(@INIT)
    unless ordered_charts.has_once()
      if (list = ordered_charts.data('js'))
        @render_list(list)
      ordered_charts.add_once()
    @toggle_list()

    $(@FORM).on 'pjax:submit', (event, options) =>
      RailsAdmin.FilterBoxConcept.merge_params(options, @CHART_ID)

  leave: =>
    (@charts || {}).each (id, chart) ->
      chart.stopRefresh()
    $(@FORM).off 'pjax:submit'

  ### list = {
        uid_0: [
          { index: uid_0, input: {name: 'field', value: 'field_value'},   label: {name: 'Field', value: 'FieldValue'} },
          { index: uid_0, input: {name: 'calculation', value: 'average'}, label: {name: 'Calculation', value: 'average'} }
        ],
        uid_1: [...]
      }
  ###
  render_list: (list) =>
    return unless list.present()

    list = @json_to_list(list.to_json()) if list.is_a String
    $(@ADDED_LIST).html list.html_map (uid, options) =>
      @render_item(options)
    @toggle_list()

  append_item: (options) =>
    unless $("#{@ADDED_ITEM}[data-key='#{@uniq_key(options)}']").length
      $(@ADDED_LIST).append @render_item(options)
      @toggle_list()
      RailsAdmin.InlineChooseConcept.clear()

  remove_item: (item) =>
    item.remove()
    @toggle_list()
    RailsAdmin.InlineChooseConcept.clear()

  render_item: (options) =>
    p @ADDED_ITEM, data: { key: @uniq_key(options) }, => [
      a '.delete', i('.fa.fa-trash-o.fa-fw'), href: '#'
      options.html_map (option) =>
        span -> [
          span '.label.label-info', option.label.name
          '&nbsp;'.html_safe(true)
          span -> option.label.value
          '&nbsp;'.html_safe(true)
        ]
      options.html_map (option) =>
        input type: 'hidden', name: "c[#{option.index}][#{option.input.name}]", value: option.input.value
    ]

  current_item: =>
    index = $.unique_id(5)
    $(@INPUTS).each_with_object [], (input, memo) =>
      category = { value: @category_name(input), text: @category_label(input) }
      option = input.find(':selected')[0]
      memo.push {
        index: index,
        input: { name: category.value, value: option.value },
        label: { name: category.text, value: option.text }
      }

  ### return = [
    {field: 'field_0', calculation: 'average'},
    {field: 'field_1', calculation: 'minimum'},
    {...}
  ]
  ###
  current_fields: =>
    $(@ADDED_ITEM).each_with_object [], (wrapper, fields) =>
      inputs = wrapper.find('input')
      fields.push @categories().each_with_object {}, (category, memo) ->
        memo[category] = inputs.filter("[name$='[#{category}]']").first().val()

  #### PRIVATE ####

  json_to_list: (json) =>
    json.each_with_object {}, (options, list) =>
      index = $.unique_index()
      list[index] = options.each_with_object [], (category, value, memo) =>
        return unless (fields = @available_fields()[category])?[value]
        memo.push {
          index: index,
          input: { name: category, value: value },
          label: { name: fields._label, value: fields[value] }
        }

  available_fields: =>
    @_available_fields ||= $(@INPUTS).each_with_object {}, (select, categories) =>
      fields = select.find('option').each_with_object {}, (option, memo) ->
        memo[option.val()] = option.text()
      fields._label = @category_label(select)
      categories[@category_name(select)] = fields

  categories: =>
    @available_fields().keys()

  category_name: (select) ->
    select.attr('name').match(/\[(\w+)\]$/)[1]

  category_label: (select) ->
    $("label[for='#{select.attr('id')}']").html()

  uniq_key: (options) ->
    options.map((option) => option.input.value).join('-')

  toggle_list: =>
    if $(@ADDED_ITEM).length
      $(@ADDED_LIST).show()
    else
      $(@ADDED_LIST).hide()
