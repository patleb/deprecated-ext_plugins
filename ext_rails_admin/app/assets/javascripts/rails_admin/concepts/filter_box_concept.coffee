# TODO https://talosintelligence.com/vulnerability_reports/TALOS-2017-0450

class RailsAdmin.FilterBoxConcept
  constants: =>
    INIT: 'ID'
    CONTAINER: 'ID'
    FILTERS: => "#{@CONTAINER} > p"
    OPTIONS: 'ID'
    LINK: 'CLASS'
    FORM: 'CLASS'
    CLEAR: 'CLASS'

  document_on: => [
    'click', "#{@CONTAINER} .delete", (event, target) ->
      form = target.parents('form')
      target.parents('.filter').remove()

    'click', "#{@CONTAINER} .switch-select", (event, target) ->
      selected_select = target.siblings('select:visible')
      not_selected_select = target.siblings('select:hidden')
      not_selected_select.attr('name', not_selected_select.data('name')).show('slow')
      selected_select.attr('name', null).hide('slow')
      target.find('i').toggleClass("icon-plus icon-minus")

    'change', "#{@CONTAINER} .switch-additional-fieldsets", (event, target) ->
      selected_option = target.find('option:selected')
      if (klass = $(selected_option).data('additional-fieldset'))
        target.siblings(".additional-fieldset:not(.#{klass})").hide('slow')
        target.siblings(".#{klass}").show('slow')
      else
        target.siblings('.additional-fieldset').hide('slow')

    'click', "#{@OPTIONS} a", (event, target) =>
      data = target.data('js')
      field_name = data.name
      unless @uniq_filters[field_name]
        @uniq_filters[field_name] = true
        @append
          label: data.label
          name:  field_name
          type:  data.type
          value: data.value
          operator: data.operator
          select_options: data.options
          index: $.unique_id(5)
          datetimepicker_format: data.datetimepicker_format

    'click', "#{@FILTERS} .delete", (event, target) =>
      field_name = target.closest('p').data('field_name')
      @uniq_filters[field_name] = false

    'click', @CLEAR, (event, target) =>
      $(@CONTAINER).html("")
      target.parent().siblings("input[type='search']").val("")
      target.parents("form").submit()
  ]

  ready: =>
    $("#{@LINK} > a").on 'pjax:click', (event, options) =>
      url = $.parse_location(options.url)
      params = $.flat_params(url.search)
      params = $.merge_params(params, $(@FORM).serialize())
      url.search = $.param(params)
      options.url = url.href

    $(@FILTERS).remove()
    if (filters = $(@INIT).data('js'))?
      filters.each (options) =>
        @append(options)

    @uniq_filters = {}
    $(@FILTERS).each (i, filter) =>
      filter = $(filter)
      field_name = filter.data('field_name')
      if @uniq_filters[field_name]
        filter.remove()
      else
        @uniq_filters[field_name] = true

  leave: =>
    $("#{@LINK} > a").off 'pjax:click'

  #### PRIVATE ####

  append: (options = {}) ->
    { label, name, type, value, operator, select_options, index, init, datetimepicker_format } = options
    if value.is_a(Array)
      value = value.map (val) -> val.to_s().safe_text()
    else
      value = value.to_s().safe_text()
    value_name = "f[#{name}][#{index}][v]"
    operator_name = "f[#{name}][#{index}][o]"
    switch type
      when 'boolean'
        control = "
          <select class='input-sm form-control' name='#{value_name}'>
            <option value='_discard'>...</option>
            <option value='true' #{@selected value, 'true'}>#{I18n.t('true')}</option>
            <option value='false' #{@selected value, 'false'}>#{I18n.t('false')}</option>
            <option disabled='disabled'>---------</option>
            <option value='_present' #{@selected value, '_present'}>#{I18n.t('is_present')}</option>
            <option value='_blank' #{@selected value, '_blank'}>#{I18n.t('is_blank')}</option>
          </select>
          "
      when 'date', 'datetime', 'timestamp'
        control = "
          <select class='switch-additional-fieldsets input-sm form-control' name='#{operator_name}'>
            <option #{@selected operator, 'default'} data-additional-fieldset='default' value='default'>#{I18n.t('date')}</option>
            <option #{@selected operator, 'between'} data-additional-fieldset='between' value='between'>#{I18n.t('between_and_')}</option>
            <option #{@selected operator, 'today'} value='today'>#{I18n.t('today')}</option>
            <option #{@selected operator, 'yesterday'} value='yesterday'>#{I18n.t('yesterday')}</option>
            <option #{@selected operator, 'this_week'} value='this_week'>#{I18n.t('this_week')}</option>
            <option #{@selected operator, 'last_week'} value='last_week'>#{I18n.t('last_week')}</option>
            <option disabled='disabled'>---------</option>
            <option #{@selected operator, '_not_null'} value='_not_null'>#{I18n.t('is_present')}</option>
            <option #{@selected operator, '_null'} value='_null'>#{I18n.t('is_blank')}</option>
          </select>
          "
        if type == 'date'
          size = 20
          input_type = 'date'
        else
          size = 25
          input_type = 'datetime'
        readonly = if Device.touched then "readonly='readonly'" else ''
        additional_control = "
          <input
            #{readonly}
            type='text'
            name='#{value_name}[]' value='#{value[0] || ''}'
            size='#{size}'
            class='#{input_type} additional-fieldset default input-sm form-control'
            style='display:#{if !operator || operator == 'default' then 'inline-block' else 'none'};'
          />
          <input
            #{readonly}
            type='text'
            name='#{value_name}[]'
            size='#{size}'
            placeholder='-∞'
            value='#{value[1] || ''}'
            class='#{input_type} additional-fieldset between input-sm form-control'
            style='display:#{if operator == 'between' then 'inline-block' else 'none'};'
          />
          <input
            #{readonly}
            type='text'
            name='#{value_name}[]'
            size='#{size}'
            placeholder='∞'
            value='#{value[2] || ''}'
            class='#{input_type} additional-fieldset between input-sm form-control'
            style='display:#{if operator == 'between' then 'inline-block' else 'none'};'
          />
          "
      when 'enum'
        multiple = !!(value instanceof Array)
        control = "
          <select
            style='display:#{if multiple then 'none' else 'inline-block'}'
            class='select-single input-sm form-control'
            data-name='#{value_name}'
            #{if multiple then '' else "name='#{value_name}'"}
          >
            <option value='_discard'>...</option>
            <option #{@selected value, '_present'} value='_present'>#{I18n.t('is_present')}</option>
            <option #{@selected value, '_blank'} value='_blank'>#{I18n.t('is_blank')}</option>
            <option disabled='disabled'>---------</option>
            #{select_options}
          </select>
          <select
            multiple='multiple'
            class='select-multiple input-sm form-control'
            style='display:#{if multiple then 'inline-block' else 'none'}'
            data-name='#{value_name}[]'
            #{if multiple then "name='#{value_name}[]'" else ''}
          >
            #{select_options}
          </select>
          <a href='#' class='switch-select'><i class='icon-#{if multiple then 'minus' else 'plus'}'></i></a>
          "
      when 'string', 'text', 'belongs_to_association'
        control = "
          <select
            class='switch-additional-fieldsets input-sm form-control'
            value='#{operator}'
            name='#{operator_name}'
          >
            <option data-additional-fieldset='additional-fieldset' #{@selected operator, 'like'} value='like'>#{I18n.t('contains')}</option>
            <option data-additional-fieldset='additional-fieldset' #{@selected operator, 'is'} value='is'>#{I18n.t('is_exactly')}</option>
            <option data-additional-fieldset='additional-fieldset' #{@selected operator, 'starts_with'} value='starts_with'>#{I18n.t('starts_with')}</option>
            <option data-additional-fieldset='additional-fieldset' #{@selected operator, 'ends_with'} value='ends_with'>#{I18n.t('ends_with')}</option>
            <option disabled='disabled'>---------</option>
            <option #{@selected operator, '_not_null'} value='_not_null'>#{I18n.t('is_present')}</option>
            <option #{@selected operator, '_null'} value='_null'>#{I18n.t('is_blank')}</option>
          </select>
          "
        additional_control = "
          <input
            type='text'
            name='#{value_name}'
            value='#{value}'
            class='additional-fieldset input-sm form-control'
            style='display:#{if operator == '_blank' || operator == '_present' then 'none' else 'inline-block'};'
          />
          "
      when 'integer', 'decimal', 'float', 'foreign_key'
        control = "
          <select class='switch-additional-fieldsets input-sm form-control' name='#{operator_name}'>
            <option #{@selected operator, 'default'} data-additional-fieldset='default' value='default'>#{I18n.t('number')}</option>
            <option #{@selected operator, 'between'} data-additional-fieldset='between' value='between'>#{I18n.t('between_and_')}</option>
            <option disabled='disabled'>---------</option>
            <option #{@selected operator, '_not_null'} value='_not_null'>#{I18n.t('is_present')}</option>
            <option #{@selected operator, '_null'} value='_null'>#{I18n.t('is_blank')}</option>
          </select>
          "
        additional_control = "
          <input
            type='number'
            name='#{value_name}[]'
            value='#{value[0] || ''}'
            class='additional-fieldset default input-sm form-control'
            style='display:#{if !operator || operator == 'default' then 'inline-block' else 'none'};'
          />
          <input
            type='number'
            name='#{value_name}[]'
            placeholder='-∞'
            value='#{value[1] || ''}'
            class='additional-fieldset between input-sm form-control'
            style='display:#{if operator == 'between' then 'inline-block' else 'none'};'
          />
          <input
            type='number'
            name='#{value_name}[]'
            placeholder='∞'
            value='#{value[2] || ''}'
            class='additional-fieldset between input-sm form-control'
            style='display:#{if operator == 'between' then 'inline-block' else 'none'};'
          />
          "
      else
        control = "
          <input type='text' class='input-sm form-control' name='#{value_name}' value='#{value}'/>
          "

    content = $("
      <p data-field_name='#{name}' class='filter form-search'>
        <span class='label label-info form-label'>
          <a href='#' class='delete'>
            <i class='fa fa-trash-o fa-fw icon-white'></i>
            #{label}
          </a>
        </span>
        #{control}
        #{additional_control || ''}
      </p>
      ")

    $(@CONTAINER).append(content)
    content.find('.date, .datetime').datetimepicker(
      locale: I18n.locale
      showClear: true
      ignoreReadonly: true
      showTodayButton: true
      format: datetimepicker_format
    )

  selected: (value, option) ->
    if value == option then 'selected="selected"' else ''
