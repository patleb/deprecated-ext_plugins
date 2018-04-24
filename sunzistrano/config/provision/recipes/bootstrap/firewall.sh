# TODO https://jkraemer.net/2015/09/fail2ban-with-devise-based-rails-apps

sun.install "ufw"
sun.install "fail2ban"

# Profiles
# /etc/services
# /etc/ufw/applications.d/*
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
yes | ufw enable

if service --status-all | grep -Fq netfilter-persistent; then
  systemctl disable netfilter-persistent
fi
systemctl enable ufw
