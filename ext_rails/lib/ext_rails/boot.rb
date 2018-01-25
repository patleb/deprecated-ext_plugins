require 'bootsnap/setup'
# require 'faster_path'
# require "faster_path/optional/monkeypatches"
# FasterPath.sledgehammer_everything!
# https://thinkwhere.wordpress.com/2016/03/04/strace-and-ruby-prof-to-identify-slow-rails-startup-on-wikimaps/

if ENV['EXT_RAILS_BOOT']
  require "benchmark"

  def require(file_name)
    result = nil

    time = Benchmark.realtime do
      result = super
    end

    threshold = ENV['EXT_RAILS_BOOT'].to_f
    if time > (threshold > 0 ? threshold : 0.1)
      puts "#{time} #{file_name}"
    end

    result
  end
end

# time EXT_RAILS_BOOT=0.1 bundle exec rake environment | sort
# RUBYOPT=-rbumbler/go bundle exec bumbler -t 10 --initializers
