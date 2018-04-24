<% %w(
  apt-transport-https
  autoconf
  bison
  build-essential
  ca-certificates
  git
  libcurl4-openssl-dev
  libffi-dev
  libgdbm-dev
  libgdbm3
  libncurses5-dev
  libreadline-dev
  libssl-dev
  libxml2-dev
  libxslt1-dev
  libyaml-dev
  openssh-server
  openssl
  zlib1g-dev
).each do |package| %>

  sun.install "<%= package %>"

<% end %>
