CTOP_VERSION=<%= @sun.docker_ctop %>

wget "https://github.com/bcicen/ctop/releases/download/v$CTOP_VERSION/ctop-$CTOP_VERSION-linux-amd64" -O /usr/local/bin/ctop

chmod +x /usr/local/bin/ctop
