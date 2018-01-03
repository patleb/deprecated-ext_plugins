module ActiveTask
  class Base
    EXIT_CODE_HELP = 10

    STEPS_ARGS = %i(
      only
      except
    ).freeze

    RAILS_ARGS = %i(
      env
      app
      root
    ).freeze

    GEMS_ARGS = %i(
      trace
      silent
      format
      require
    ).freeze

    attr_reader :rake, :task, :options

    def self.protected_args
      STEPS_ARGS + RAILS_ARGS + GEMS_ARGS
    end

    def self.steps
      []
    end

    def self.args
      {}
    end

    def self.defaults
      {}
    end

    def initialize(rake, task, args = {}, **defaults)
      if (@debug = ENV['DEBUG'].to_b)
        ENV['DEBUG_RESPONSE'] = 'true'
      end

      @rake, @task = rake, task
      @options = self.class.defaults.with_indifferent_access.merge!(defaults).merge!(args.to_h)
    end

    def before_run; end

    def run
      _save_environment
      I18n.locale = :en
      Time.zone = 'UTC'
      unless _parse_args
        before_run
        _steps.each do |step|
          puts "[#{Time.current.utc}][step] #{step}".yellow
          send step
        end
      end
    ensure
      _restore_environment
    end

    def reload_settings_yml
      SettingsYml.clean(force: true)
    end

    def puts_downloading(file_name, remainder, total)
      remainder = number_to_human_size remainder
      total = number_to_human_size total
      puts "Downloading #{file_name}[#{total}] remaining #{remainder}"
    end

    def puts(obj = '', *arg)
      task.puts(obj, *arg)
    end

    def method_missing(name, *args, &block)
      rake.__send__(name, *args, &block)
    end

    def respond_to_missing?(name, include_private = false)
      rake.respond_to?(name, include_private) || super
    end

    private

    def _parse_args
      rails_args = @options.extract!(*RAILS_ARGS)
      @options = OpenStruct.new(@options)
      parser = OptionParser.new

      parser.banner = "Usage: rake #{task.name} #{'-- [options]' if self.class.args.any?}"
      self.class.args.each do |arg_name, arg_options|
        if self.class.protected_args.include? arg_name
          raise "protected argurment [#{arg_name}] cannot be used"
        end
        parser.on(*arg_options){ |value| @options[arg_name] = value }
      end
      STEPS_ARGS.each do |arg|
        parser.on("--#{arg}=#{arg.to_s.upcase}", Array){ |list| @options[arg] = list }
      end
      RAILS_ARGS.each do |arg|
        parser.on("--#{arg}=RAILS_#{arg.to_s.upcase}"){ |value| rails_args[arg] = value }
      end
      # rake
      parser.on("--trace"){ Rake.verbose(true) }
      # whenever
      parser.on("--silent"){ Rake.verbose(false) }
      # rspec
      parser.on("--format"){}
      parser.on("--require"){}

      parser.on("-h", "--help", task.full_comment.sub('-- [options]', '')) do
        puts(parser.to_s.split("\n").reject! do |line|
          line.match /--(#{self.class.protected_args.join('|')}|$)/
        end.join("\n"))

        exit EXIT_CODE_HELP
      end
      # ... for some unknown reason
      parser.on("--"){}

      args = parser.order!(ARGV){}
      parser.parse! args
      rails_args.each do |arg, value|
        ENV["RAILS_#{arg.to_s.upcase}"] = value
      end

      false
    rescue SystemExit => exception
      if exception.status != EXIT_CODE_HELP
        raise
      else
        true
      end
    end

    def _steps
      steps = self.class.steps

      if @options.only.present?
        steps.select!{ |step| step.to_s.in? @options.only }
      end

      if @options.except.present?
        steps.reject!{ |step| step.to_s.in? @options.except }
      end

      steps
    end

    def _save_environment
      @_environment = {}
      RAILS_ARGS.each do |arg|
        name = "RAILS_#{arg.to_s.upcase}"
        @_environment[name] = ENV[name]
      end
      ExtRake.config.env_vars.each do |var|
        name = var.to_s.upcase
        @_environment[name] = ENV[name]
      end
      @_environment[:locale] = I18n.locale
      @_environment[:time_zone] = Time.zone
      @_environment[:currency] = Money.default_currency if defined?(::MoneyRails)
      @_environment[:s3_versionned] = ExtRake.config.s3_versionned?
      @_environment[:archive] = ExtRake.config.archive
    end

    def _restore_environment
      RAILS_ARGS.each do |arg|
        name = "RAILS_#{arg.to_s.upcase}"
        ENV[name] = @_environment[name]
      end
      ExtRake.config.env_vars.each do |var|
        name = var.to_s.upcase
        ENV[name] = @_environment[name]
      end
      SettingsYml.rollback!
      I18n.locale = @_environment[:locale]
      Time.zone = @_environment[:time_zone]
      MoneyRails.configure{ |config| config.default_currency = @_environment[:currency] } if defined?(::MoneyRails)
      ExtRake.config.s3_versionned = @_environment[:s3_versionned]
      ExtRake.config.archive = @_environment[:archive]
      @_environment.clear
    end
  end
end
