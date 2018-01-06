# https://github.com/ruby-debug/ruby-debug-ide/issues/80
if $LOADED_FEATURES.any?{ |f| f.include? 'debase' }
  require 'timeout'
  module Timeout
    def timeout(sec, klass = nil, message = nil)
      yield(sec)
    end
    module_function :timeout
  end
end
