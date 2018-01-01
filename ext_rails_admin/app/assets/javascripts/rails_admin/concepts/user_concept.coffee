class RailsAdmin.UserConcept
  global: true

  constants: ->
    PROFILE: 'ID'

  ready_once: =>
    @profile = $(@PROFILE).data('js')

  edit_url: =>
    Routes.url_for('edit', model_name: @profile.model_name, id: @profile.id)

  edit_path: =>
    Routes.path_for('edit', model_name: @profile.model_name, id: @profile.id)
