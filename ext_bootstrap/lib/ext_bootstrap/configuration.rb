module ExtBootstrap
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
    attr_writer :theme

    def theme
      @theme || 'paper'
    end
  end
end
