module ExtGlobals
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
    attr_accessor :skip_migrations
    attr_writer :parent_model
    attr_writer :expires_in, :touch_in
    attr_writer :output_length

    def parent_model
      @parent_model ||= '::ActiveRecord::Base'
    end

    def expires_in
      @expires_in ||= 1.month
    end

    def touch_in
      @touch_in ||= expires_in * 0.5
    end

    def output_length
      @output_length ||= 80
    end
  end
end
