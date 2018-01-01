class RailsAdmin.ModalFormConcept
  constants: ->
    DIALOG: 'ID'
    CANCEL: 'ID'
    SAVE: 'ID'
    NEW: 'CLASS'
    EDIT: 'CLASS'
    EDITABLE: 'CLASS'

  document_on: => [
    'click', @CANCEL, (event) =>
      $(@DIALOG).modal('hide')

    'click', @SAVE, (event) =>
      form = $(@DIALOG).find('form')
      form.submit()

    'click', @NEW, (event, target) =>
      { params, select_id } = target.data('js')
      url = Routes.url_for('new', params)
      @render_modal(url, select_id)

    'click', @EDIT, (event, target) =>
      { params, select_id } = target.data('js')
      params = { id: $("##{select_id}").val() }.merge(params)
      url = Routes.url_for('edit', params)
      @render_modal(url, select_id)

    'change', @EDITABLE, (event, target) =>
      edit_link = $("##{@EDITABLE_CLASS}_#{target.attr('id')}")
      edit_link.toggleClass('disabled', target.val().blank())
  ]

  render_modal: (url, select_id) =>
    dialog = $(@DIALOG)
    return dialog.modal('show') if dialog.length

    dialog = $("
      <div class='modal fade' id='#{@DIALOG_ID}'>
        <div class='modal-dialog'>
          <div class='modal-content'>
            <div class='modal-header'>
              <a href='#' data-dismiss='modal' class='close'>×</a>
              <h3 class='modal-header-title'>...</h3>
            </div>
            <div class='modal-body'>...</div>
            <div class='modal-footer'>
              <a href='#' class='btn btn-default' id='#{@CANCEL_ID}'>
                <i class='icon-remove'></i>
                #{I18n.t('form_cancel')}
              </a>
              <a href='#' class='btn btn-primary' id='#{@SAVE_ID}'>
                <i class='icon-white icon-ok'></i>
                #{I18n.t('form_save')}
              </a>
            </div>
          </div>
        </div>
      </div>
    ")

    dialog.modal(keyboard: true, backdrop: true, show: true).on('hidden.bs.modal', (event) -> $(this).remove())

    # fix race condition with modal insertion in the dom (Chrome => Team/add a new fan => #modal not found when it should have).
    # Somehow .on('show') is too early, tried it too.
    setTimeout(=>
      $.ajax(
        url: url
        content_error: "#{@DIALOG} .modal-content"
        success: (data, status, xhr) =>
          @render_form(data, select_id)
      )
    , 200)

  #### PRIVATE ####

  render_form: (view, select_id) =>
    dialog = $(@DIALOG)

    body = dialog.find('.modal-body')
    body.html(view)

    form = body.find('form')
    form.on 'pjax:success', (e, data, status, xhr) =>
      @update(select_id, data)
      dialog.modal('hide')
    form.on 'pjax:error', (e, xhr, status, error) =>
      @render_form(xhr.responseText.presence() || error, select_id)

    title = dialog.find('.modal-header-title')
    title.text(form.data('js')?.title)

    $.dom_ready(scoped: true)

  update: (select_id, data) =>
    fields = RailsAdmin.FieldConcept.fields
    if fields.has_key(select_id)
      select = fields[select_id]
      select.update_input(data)
    else
      input = $("##{select_id}")
      RailsAdmin.FieldConcept.SelectElement::update_select(input, data)
