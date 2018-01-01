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
