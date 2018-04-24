<% @sun.list_recipes(%W(
  bootstrap/upgrade__UPGRADE__
  bootstrap/time_locale
  bootstrap/mount
  bootstrap/swap
  bootstrap/packages
  bootstrap/backports
  bootstrap/ssh
  bootstrap/firewall
  bootstrap/firewall/deny_mail
)) do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
