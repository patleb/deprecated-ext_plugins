<% %w(
  arp-scan
  htop
  httpie
  ifstat
  iftop
  imagemagick
  iotop
  iptraf
  iputils-ping
  jq
  nethogs
  ngrep
  nmap
  python-dev
  python-pip
  python3-pip
  software-properties-common
  tree
).each do |package| %>

  sun.install "<%= package %>"

<% end %>
