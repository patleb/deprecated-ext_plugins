module ExtThrottler
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
    attr_writer :duration

    def duration
      @duration = @duration.call if @duration.is_a? Proc
      @duration ||= 4.hours
    end
  end
end
