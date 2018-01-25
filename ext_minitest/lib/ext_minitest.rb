# TODO
# https://mattbrictson.com/minitest-and-rails
# https://coderwall.com/p/8yl45w/creating-a-test-rake-task-with-minitest
# http://blog.testdouble.com/posts/2016-12-15-rake-without-rails
# https://medium.com/@juinchiu/how-to-setup-minitest-for-your-gems-development-f29c4bee13c2
# http://mattsears.com/articles/2011/12/10/minitest-quick-reference/

module ExtMinitest
  if defined?(Rails)
    Gem.loaded_specs["ext_minitest"].dependencies.each do |d|
      begin
        require d.name
      rescue LoadError => e
        # Put exceptions here.
      end
    end
  end
end
