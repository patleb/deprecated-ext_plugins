# TODO
# http://rny.io/nginx/postgresql/2013/07/26/simple-api-with-nginx-and-postgresql.html
# https://www.phusionpassenger.com/library/install/nginx/install_as_nginx_module.html
# https://codegists.com/code/build%20openresty%20with%20passenger/
# https://www.digitalocean.com/community/tutorials/how-to-use-the-openresty-web-framework-for-nginx-on-ubuntu-16-04
# https://gist.github.com/kingtuna/7706b25c52c810b521ee375495bdc5ca
# https://blog.kurttomlinson.com/posts/how-to-install-openresty-and-passenger-on-ubuntu-16-04-xenial-xerus
# https://openresty.org/en/installation.html
# https://edzeame.wordpress.com/2016/06/07/step-by-step-configuration-of-open-resty-modules-and-a-simple-lua-text-response/

# '1.11.2.4'
OPENRESTY_VERSION=<%= @sun.openresty %>

sun.install "dirmngr"
sun.install "gnupg"

gem install passenger

echo $(which passenger) > ~/PASSENGER_PATH

sun.install "libpcre3-dev"
sun.install "perl"

wget -c https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz
tar -xvf openresty-$OPENRESTY_VERSION.tar.gz
cd openresty-$OPENRESTY_VERSION/

./configure -j2
# TODO
make -j2
make install

# configured with ext_capistrano gem
