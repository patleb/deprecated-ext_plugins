sun.mute "timedatectl set-timezone <%= @sun.timezone || 'Etc/UTC' %>"
sun.mute "locale-gen <%= @sun.locales || 'en_US en_US.UTF-8' %>"
sun.mute "dpkg-reconfigure locales"
sun.install "curl"
sun.install "ntp"
