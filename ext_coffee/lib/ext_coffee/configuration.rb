module ExtCoffee
  @@config = nil

  def self.configure
    @@config ||= Configuration.new

    if block_given?
      yield config
    end

    config
  end

  def self.config
    @@config || configure
  end

  class Configuration
    attr_accessor :debug_state_machine, :debug_trace
    attr_writer :debug, :warn

    def debug
      defined?(@debug) ? @debug : Rails.env.development?
    end

    def warn
      defined?(@warn) ? @warn : true
    end
  end
end
