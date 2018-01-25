module ExtRails
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
    attr_accessor :i18n_debug
    attr_accessor :query_debug
    attr_writer :html_extra_tags
    attr_writer :profile
    attr_writer :throttler
    attr_writer :rescue_500
    attr_writer :version
    attr_writer :skip_locking

    def html_extra_tags
      @html_extra_tags ||= []
    end

    def profile
      @profile ||= '(app|lib)/'
    end

    def throttler
      @throttler ||= Class.new do
        def self.status(key:, value:, duration: nil)
          {
            throttled: false,
            previous: nil,
            count: 0
          }
        end
      end
    end

    def rescue_500?
      defined?(@rescue_500) ? @rescue_500 : !(Rails.env.development? || Rails.env.test?)
    end

    def version
      @version ||= Rails.root.join('REVISION').exist? ? Rails.root.join('REVISION').read.first(7) : '0.1.0'
    end

    def skip_locking
      @skip_locking ||= %w(updated_at)
    end
  end
end
