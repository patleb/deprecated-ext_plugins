<% @sun.list_recipes(%W(
  docker/engine__DOCKER__
  docker/compose__DOCKER_COMPOSE__
  docker/postgres
  docker/tools/ctop__DOCKER_CTOP__
  docker/tools/portainer
)) do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
