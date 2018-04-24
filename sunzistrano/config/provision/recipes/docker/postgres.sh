PG_VERSION=<%= @sun.postgres %>
PG_MAJOR=$(sun.major_version "$PG_VERSION")
PG_CONF="/etc/postgresql/$PG_MAJOR/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_MAJOR/main/pg_hba.conf"
INTERNAL_IP=$(sun.internal_ip)
DOCKER_BRIDGE=$(ifconfig docker0 | grep "inet addr:" | awk '{print $2}' | sed "s/.*://")

echo "listen_addresses = 'localhost, $DOCKER_BRIDGE'" >> "$PG_CONF"
echo "host    all             all             172.17.0.0/16            md5" >> "$PG_HBA"
echo "host    all             all             172.18.0.0/16            md5" >> "$PG_HBA"
echo "host    all             all             $INTERNAL_IP/32          md5" >> "$PG_HBA"

ufw allow in from 172.17.0.0/16 to $DOCKER_BRIDGE port 5432
ufw allow in from 172.18.0.0/16 to $DOCKER_BRIDGE port 5432
ufw reload

systemctl restart postgresql

sun.move '/lib/systemd/system/postgresql_restart.service'

systemctl enable postgresql_restart
