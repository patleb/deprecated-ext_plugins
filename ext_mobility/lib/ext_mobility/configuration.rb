module ExtMobility
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
    attr_writer :polymorphic_tables

    # bundle exec rake db:migrate:down VERSION=20990000000005
    def polymorphic_tables
      @polymorphic_tables ||= []
    end
  end
end
