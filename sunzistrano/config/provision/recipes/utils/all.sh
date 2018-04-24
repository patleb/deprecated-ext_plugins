<% @sun.list_recipes(%W(
  utils/tools
  utils/nodejs__NODEJS__
  utils/goaccess
  utils/sysstat
  utils/monit
  #{'utils/mailcatcher' if @sun.env.vagrant?}
)) do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
