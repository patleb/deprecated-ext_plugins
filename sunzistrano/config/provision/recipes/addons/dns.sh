export INTERFACE=$(sun.default_interface)
export SERVER_NAME=<%= @sun.server %>

sun.install 'dnsmasq'

sun.backup_compile '/etc/dnsmasq.conf'
sun.backup_defaults '/etc/resolv.conf'
sun.backup_compile '/etc/dhcp/dhclient.conf'

# no sun.compare_defaults since there are some static IPs
sun.backup_defaults '/etc/hosts'
<%= SunCap.build_hosts(@sun.admin_name, @sun.server) %>

ufw allow domain
ufw reload

systemctl restart networking
systemctl enable dnsmasq
systemctl restart dnsmasq
