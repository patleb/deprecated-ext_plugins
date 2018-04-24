if [[ ! -s "/home/deployer/.rbenv" ]]; then
  sun.install "libjemalloc-dev"
fi

sudo su - deployer << 'EOF'
  PLUGINS_PATH=/home/deployer/.rbenv/plugins
  PROFILE=/home/deployer/.bashrc
  RUBY_VERSION=<%= @sun.rbenv_ruby %>

  if [[ ! -s "/home/deployer/.rbenv" ]]; then
    git clone git://github.com/sstephenson/rbenv.git /home/deployer/.rbenv
    git clone git://github.com/sstephenson/ruby-build.git $PLUGINS_PATH/ruby-build
    git clone git://github.com/sstephenson/rbenv-gem-rehash.git $PLUGINS_PATH/rbenv-gem-rehash
    git clone git://github.com/dcarley/rbenv-sudo.git $PLUGINS_PATH/rbenv-sudo

    echo '<%= @sun.rbenv_export %>' >> $PROFILE
    echo '<%= @sun.rbenv_init %>' >> $PROFILE
    echo 'gem: --no-ri --no-rdoc' > /home/deployer/.gemrc
  else
    cd /home/deployer/.rbenv && git pull
    cd $PLUGINS_PATH/ruby-build && git pull
    cd $PLUGINS_PATH/rbenv-gem-rehash && git pull
    cd $PLUGINS_PATH/rbenv-sudo && git pull
    cd ~
  fi

  <%= @sun.rbenv_export %>
  <%= @sun.rbenv_init %>

  RUBY_CONFIGURE_OPTS='--with-jemalloc --enable-shared' rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
  gem install bundler
EOF
