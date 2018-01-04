Sunzistrano
===========

```
"The supreme art of war is to subdue the enemy without fighting." - Sunzi
```

Sunzistrano is the easiest [server provisioning](http://en.wikipedia.org/wiki/Provisioning#Server_provisioning) utility designed for mere mortals. If Chef or Puppet is driving you nuts, try Sunzistrano!

Sunzistrano assumes that modern Linux distributions have (mostly) sane defaults and great package managers.

Its design goals are:

* **It's just shell script.** No clunky Ruby DSL involved. Most of the information about server configuration on the web is written in shell commands. Just copy-paste them, rather than translate it into an arbitrary DSL. Also, Bash is the greatest common denominator on minimum Linux installs.
* **Focus on diff from default.** No big-bang overwriting. Append or replace the smallest possible piece of data in a config file. Loads of custom configurations make it difficult to understand what you are really doing.
* **Always use the root user.** Think twice before blindly assuming you need a regular user - it doesn't add any security benefit for server provisioning, it just adds extra verbosity for nothing. However, it doesn't mean that you shouldn't create regular users with Sunzistrano - feel free to write your own recipes.
* **Minimum dependencies.** No configuration server required. You don't even need a Ruby runtime on the remote server.

Credits
-------

Special thanks to the owner of [sunzi](https://github.com/kenn/sunzi), the present gem is pretty much a rewritten copy suited to work with Rails and Capistrano.
