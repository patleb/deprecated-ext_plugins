DEPLOYER_PWD=<%= @sun.deployer_password %>
DEPLOYER_PATH=/home/deployer

adduser deployer --gecos '' --disabled-password
echo "deployer:$DEPLOYER_PWD" | sudo chpasswd
adduser deployer sudo

mkdir $DEPLOYER_PATH/.ssh
chmod 700 $DEPLOYER_PATH/.ssh
<%= SunCap.build_authorized_keys %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
chown -R deployer:deployer $DEPLOYER_PATH

sun.compile "/etc/sudoers.d/deployer" 0440 root:root
