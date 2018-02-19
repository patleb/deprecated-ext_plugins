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
      key = @uniq_key()
      unless @uniq_charts[key]
        @uniq_charts[key] = true
        @append_chart()
        @toggle_list()

    'click', "#{@ADDED_ITEM} .delete", (event, target) =>
      wrapper = target.closest(@ADDED_ITEM)
      key = wrapper.data('key')
      wrapper.remove()
      @uniq_charts[key] = false
      @toggle_list()

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

    @charts = $(@CONFIG).each_with_object (chart, result) ->
      config = chart.data('js')
      result[config.id] = new Chartkick[config.type](config.id, config.source, config.options)
    , {}

    ordered_charts = $(@INIT)
    unless ordered_charts.has_once()
      ordered_charts.data('js')?.each (i, options) =>
        @append_chart(options)
      ordered_charts.add_once()

    @uniq_charts = {}
    $(@ADDED_ITEM).each (i, chart) =>
      chart = $(chart)
      key = chart.data('key')
      if @uniq_charts[key]
        chart.remove()
      else
        @uniq_charts[key] = true

    $(@FORM).on 'pjax:submit', (event, options) =>
      url = $.parse_location(options.url, hash: @CHART_ID)
      params = $.flat_params(url.search)
      params = $.merge_params(params, $(@FILTER_BOX_FORM).serialize())
      url.search = $.param(params)
      options.url = url.href

    @toggle_list()

  leave: =>
    (@charts || {}).each (id, chart) ->
      chart.stopRefresh()
    $(@FORM).off 'pjax:submit'

  #### PRIVATE ####

  # TODO add additional inputs instead of using filters
  append_chart: (options = null) =>
    $(@ADDED_LIST).append(
      p @ADDED_ITEM, data: { key: @uniq_key(options) }, => [
        a '.delete', i('.fa.fa-trash-o.fa-fw'), href: '#'
        @chart_label(options)
        @chart_input(options)
      ]
    )

  chart_label: (options) =>
    label = if options?
      options.map (option) => @label(option.label.name, option.label.value)
    else
      @options().map (option) => @label(option[0].text, option[1].text)
    label.join(' ').html_safe(true)

  chart_input: (options) =>
    input = if options?
      options.map (option) => @input(option.index, option.input.name, option.input.value)
    else
      index = $.unique_id(5)
      @options().map (option) => @input(index, option[0].value, option[1].value)
    input.join('').html_safe(true)

  uniq_key: (options) ->
    key = if options?
      options.map (option) => option.input.value
    else
      @options().map (option) => option[1].value
    key.join('-')

  options: =>
    $(@INPUTS).to_a().map (input) ->
      input = $(input)
      name = { value: input.attr('name'), text: $("label[for='#{input.attr('id')}']").html() }
      value = input.find(':selected')[0]
      [name, value]

  label: (name, value) ->
    span -> [
      span '.label.label-info', name
      '&nbsp;'.html_safe(true)
      span -> value
    ]

  input: (index, name, value) ->
    if name.starts_with 'chart_form['
      name = name.sub(/^\w+\[(\w+)\]/, "c[#{index}][$1]")
    else
      name = "c[#{index}][#{name}]"
    input type: 'hidden', name: name, value: value

  toggle_list: =>
    if @uniq_charts.values().except(false).length
      $(@ADDED_LIST).show()
    else
      $(@ADDED_LIST).hide()
