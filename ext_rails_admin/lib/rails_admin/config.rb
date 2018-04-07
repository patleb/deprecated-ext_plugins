require 'rails_admin/config/configurable'
require 'rails_admin/config/groupable'
require 'rails_admin/config/has_description'
require 'rails_admin/config/has_fields'
require 'rails_admin/config/has_groups'
require 'rails_admin/config/hideable'
require 'rails_admin/config/inspectable'
require 'rails_admin/config/proxyable'

require 'rails_admin/config/actions'
require 'rails_admin/config/fields'
require 'rails_admin/config/sections'

module RailsAdmin
  autoload :AbstractModel, 'rails_admin/abstract_model'
  # Setup RailsAdmin
  #
  # Given the first argument is a model class, a model class name
  # or an abstract model object proxies to model configuration method.
  #
  # If only a block is passed it is stored to initializer stack to be evaluated
  # on first request in production mode and on each request in development. If
  # initialization has already occured (in other words RailsAdmin.setup has
  # been called) the block will be added to stack and evaluated at once.
  #
  # Otherwise returns RailsAdmin::Config class.
  #
  # @see RailsAdmin::Config
  def self.config(entity = nil, &block)
    if entity
      RailsAdmin::Config.model(entity, &block)
    elsif block_given?
      block.call(RailsAdmin::Config)
    else
      RailsAdmin::Config
    end
  end

  # TODO replace Kaminari view helper by inline ruby helper --> slow like filter_box (replace all partials)
  # https://www.reddit.com/r/webdev/comments/4bf9hc/how_bad_is_ruby_on_rails_performance_really/
  def self.show_path(model_name:, id:)
    @show_path ||= begin
      path = RailsAdmin::Engine.routes.url_helpers.send(:show_path, model_name: '__MODEL_NAME__', id: '__ID__')
      path.sub('/__MODEL_NAME__/__ID__', '')
    end
    [@show_path, model_name, id].join('/')
  end

  module Config
    autoload :LazyModel, 'rails_admin/config/lazy_model'
    autoload :Model, 'rails_admin/config/model'

    # @see RailsAdmin::Config.authorize_with
    DEFAULT_AUTHORIZE = proc {}

    DEFAULT_AUDIT = proc {}

    NAMESPACE_SEPARATOR = '-'

    class << self
      # Application title, can be an array of two elements
      attr_accessor :main_app_name

      # Configuration option to specify which models you want to exclude.
      attr_accessor :excluded_models

      # Configuration option to specify a whitelist of models you want to RailsAdmin to work with.
      # The excluded_models list applies against the whitelist as well and further reduces the models
      # RailsAdmin will use.
      # If included_models is left empty ([]), then RailsAdmin will automatically use all the models
      # in your application (less any excluded_models you may have specified).
      attr_accessor :included_models

      # Fields to be hidden in show, create and update views
      attr_accessor :default_hidden_fields

      # Default items per page value used if a model level option has not
      # been configured
      attr_accessor :default_items_per_page

      # Default association limit
      attr_accessor :default_associated_collection_limit

      attr_reader :default_search_operator

      # Configuration option to specify which method names will be searched for
      # to be used as a label for object records. This defaults to [:name, :title]
      attr_accessor :label_methods

      # hide blank fields in show view if true
      attr_accessor :compact_show_view

      # Tell browsers whether to use the native HTML5 validations (novalidate form option).
      attr_accessor :browser_validations

      # set parent controller
      attr_accessor :parent_controller

      # Stores model configuration objects in a hash identified by model's class
      # name.
      #
      # @see RailsAdmin.config
      attr_reader :registry

      # show Gravatar in Navigation bar
      attr_accessor :show_gravatar

      # accepts a hash of static links to be shown below the main navigation
      attr_accessor :navigation_static_links
      attr_accessor :navigation_static_label

      # yell about fields that are not marked as accessible
      attr_accessor :yell_for_non_accessible_fields

      # use a specific model as root path instead of the dashboard
      # ex.: config.root_model_name = 'module_name~model_name'
      attr_accessor :root_model_name

      # use concerns with rails_admin config blocks for each model
      # ex.: config.with_admin_concerns = true # or :reverse to include modules in reverse order
      # in app/models/admin/model_name.rb:
      #
      # module Admin::ModelName
      #   extend ActiveSupport::Concern
      #
      #   included do
      #      rails_admin do
      #        # configurations here
      #      end
      #   end
      # end
      attr_accessor :with_admin_concerns

      attr_accessor :chart_max_rows
      attr_accessor :export_max_rows

      # Setup auditing/history/versioning provider that observe objects lifecycle
      def audit_with(*args, &block)
        extension = args.shift
        if extension
          klass = RailsAdmin::AUDITING_ADAPTERS[extension]
          klass.setup if klass.respond_to? :setup
          @audit = proc do
            @auditing_adapter = klass.new(*([self] + args).compact)
          end
        elsif block
          @audit = block
        end
        @audit || DEFAULT_AUDIT
      end

      # Setup authorization to be run as a before filter
      # This is run inside the controller instance so you can setup any authorization you need to.
      #
      # By default, there is no authorization.
      #
      # @example Custom
      #   RailsAdmin.config do |config|
      #     config.authorize_with do
      #       redirect_to root_path unless warden.user.is_admin?
      #     end
      #   end
      #
      # To use an authorization adapter, pass the name of the adapter. For example,
      # to use with CanCan[https://github.com/ryanb/cancan], pass it like this.
      #
      # @example CanCan
      #   RailsAdmin.config do |config|
      #     config.authorize_with :cancan
      #   end
      #
      # See the wiki[https://github.com/sferik/rails_admin/wiki] for more on authorization.
      #
      # @see RailsAdmin::Config::DEFAULT_AUTHORIZE
      def authorize_with(*args, &block)
        extension = args.shift
        if extension
          klass = RailsAdmin::AUTHORIZATION_ADAPTERS[extension]
          klass.setup if klass.respond_to? :setup
          @authorize = proc do
            @authorization_adapter = klass.new(*([self] + args).compact)
          end
        elsif block
          @authorize = block
        end
        @authorize || DEFAULT_AUTHORIZE
      end

      # Setup configuration using an extension-provided ConfigurationAdapter
      #
      # @example Custom configuration for role-based setup.
      #   RailsAdmin.config do |config|
      #     config.configure_with(:custom) do |config|
      #       config.models = ['User', 'Comment']
      #       config.roles  = {
      #         'Admin' => :all,
      #         'User'  => ['User']
      #       }
      #     end
      #   end
      def configure_with(extension)
        configuration = RailsAdmin::CONFIGURATION_ADAPTERS[extension].new
        yield(configuration) if block_given?
      end

      def default_search_operator=(operator)
        if %w(default like starts_with ends_with is =).include? operator
          @default_search_operator = operator
        else
          raise(ArgumentError.new("Search operator '#{operator}' not supported"))
        end
      end

      # pool of all found model names from the whole application
      def models_pool
        excluded = (excluded_models.collect(&:to_s) + %w(RailsAdmin::History PaperTrail::Version PaperTrail::VersionAssociation))

        (viable_models - excluded).uniq.sort
      end

      # Loads a model configuration instance from the registry or registers
      # a new one if one is yet to be added.
      #
      # First argument can be an instance of requested model, its class object,
      # its class name as a string or symbol or a RailsAdmin::AbstractModel
      # instance.
      #
      # If a block is given it is evaluated in the context of configuration instance.
      #
      # Returns given model's configuration
      #
      # @see RailsAdmin::Config.registry
      def model(entity, &block)
        key = begin
          if entity.is_a?(RailsAdmin::AbstractModel)
            entity.model.try(:name).try(:to_sym)
          elsif entity.is_a?(Class)
            entity.name.try(:to_sym)
          elsif entity.is_a?(String) || entity.is_a?(Symbol)
            entity.to_sym
          else
            entity.class.name.to_sym
          end
        end

        @registry[key] ||= RailsAdmin::Config::LazyModel.new(entity)
        @registry[key].add_deferred_block(&block) if block
        @registry[key]
      end

      def default_hidden_fields=(fields)
        if fields.is_a?(Array)
          @default_hidden_fields = {}
          @default_hidden_fields[:edit] = fields
          @default_hidden_fields[:show] = fields
        else
          @default_hidden_fields = fields
        end
      end

      # Returns action configuration object
      def actions(&block)
        RailsAdmin::Config::Actions.init_actions!
        RailsAdmin::Config::Actions.instance_eval(&block) if block
      end

      # Returns all model configurations
      #
      # @see RailsAdmin::Config.registry
      def models
        RailsAdmin::AbstractModel.all.collect { |m| model(m) }
      end

      # Reset all configurations to defaults.
      #
      # @see RailsAdmin::Config.registry
      def reset
        @compact_show_view = true
        @browser_validations = true
        @yell_for_non_accessible_fields = true
        @authorize = nil
        @audit = nil
        @default_hidden_fields = {}
        @default_hidden_fields[:base] = [:_type]
        @default_hidden_fields[:edit] = [:id, :_id, :created_at, :created_on, :deleted_at, :updated_at, :updated_on, :deleted_on]
        @default_hidden_fields[:show] = [:id, :_id, :created_at, :created_on, :deleted_at, :updated_at, :updated_on, :deleted_on]
        @default_items_per_page = 20
        @default_associated_collection_limit = 100
        @default_search_operator = 'default'
        @excluded_models = []
        @included_models = []
        @label_methods = [:name, :title]
        @main_app_name = proc { Rails.application.title }
        @registry = {}
        @show_gravatar = false
        @navigation_static_links = {}
        @navigation_static_label = nil
        @parent_controller = '::ActionController::Base'
        @root_model_name = nil
        @with_admin_concerns = true
        @chart_max_rows = 750_000
        @export_max_rows = 750_000
        RailsAdmin::Config::Actions.reset
      end

      # Reset a provided model's configuration.
      #
      # @see RailsAdmin::Config.registry
      def reset_model(model)
        key = model.is_a?(Class) ? model.name.to_sym : model.to_sym
        @registry.delete(key)
      end

      # Get all models that are configured as visible sorted by their weight and label.
      #
      # @see RailsAdmin::Config::Hideable

      def visible_models(bindings)
        visible_models_with_bindings(bindings).sort do |a, b|
          if (weight_order = a.weight <=> b.weight) == 0
            a.label.downcase <=> b.label.downcase
          else
            weight_order
          end
        end
      end

    private

      def lchomp(base, arg)
        base.to_s.reverse.chomp(arg.to_s.reverse).reverse
      end

      def viable_models
        included_models.map(&:to_s).presence || begin
          @@system_models ||= # memoization for tests
            ([Rails.application] + Rails::Engine.subclasses.except(RailsAdmin::Engine).map(&:instance)).flat_map do |app|
              (app.paths['app/models'].to_a + app.paths.eager_load.select(&:end_with?.with('/models'))).map do |load_path|
                Dir.glob(app.root.join(load_path)).map do |load_dir|
                  Dir.glob(load_dir + '/**/*.rb').map do |filename|
                    # app/models/module/class.rb => module/class.rb => module/class => Module::Class
                    unless filename.end_with?('_decorator.rb') || filename.end_with?('/null.rb')
                      lchomp(filename, "#{app.root.join(load_dir)}/").chomp('.rb').camelize
                    end
                  end.compact
                end
              end
            end.flatten.reject{ |m| m.start_with?('Concerns::') } # rubocop:disable MultilineBlockChain
        end
      end

      def visible_models_with_bindings(bindings)
        models.collect { |m| m.with(bindings) }.select do |m|
          m.visible? &&
            RailsAdmin::Config::Actions.find(:index, bindings.merge(abstract_model: m.abstract_model)).try(:authorized?) &&
            (!m.abstract_model.embedded? || m.abstract_model.cyclic?)
        end
      end
    end

    # Set default values for configuration options on load
    reset
  end
end
