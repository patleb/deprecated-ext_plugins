DEPLOYER_HTPASSWD=<%= @sun.deployer_htpasswd || @sun.deployer_password %>

echo -n 'deployer:' >> /etc/nginx/.htpasswd
openssl passwd -apr1 "$DEPLOYER_HTPASSWD" >> /etc/nginx/.htpasswd
