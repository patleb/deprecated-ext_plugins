#= require lodash/lodash
#= require jquery/dist/jquery
#= require moment/moment
#= require moment_locales
#= require nprogress/nprogress
#= require js-cookie/src/js.cookie
#= require jstz/dist/jstz

#= require ext_coffee/logger
#= require ext_coffee/core
#= require_tree ./core
#= require ext_coffee/pjax
#= require ext_coffee/state_machine
#= require ext_coffee/tags
#= require ext_coffee/concepts
#= require_tree ./concepts

###
lodash                       # ~25kB
jquery3                      # ~30kB
moment                       # ~15kB
nprogress                    # ~2kB
ext_coffee/pjax              # ~4kB
ext_coffee/state_machine     # ~2kB
ext_coffee/(core + concepts) # ~5kB
###
