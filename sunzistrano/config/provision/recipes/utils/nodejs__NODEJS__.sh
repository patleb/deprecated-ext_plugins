NODE_VERSION=<%= @sun.nodejs %>

curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -

sun.install "nodejs"
