module RailsAdmin
  module Config
    module Actions
      class << self
        def all(scope = nil, bindings = {})
          if scope.is_a?(Hash)
            bindings = scope
            scope = :all
          end
          scope ||= :all
          actions = begin
            case scope
            when :all
              @@actions
            when :root
              @@actions.select(&:root?)
            when :collection
              @@actions.select(&:collection?)
            when :bulkable
              @@actions.select(&:bulkable?)
            when :member
              @@actions.select(&:member?)
            end
          end
          actions = actions.collect { |action| action.with(bindings) }
          bindings[:controller] ? actions.select(&:visible?) : actions
        end

        def find(custom_key, bindings = {})
          action = @@actions.detect { |a| a.custom_key == custom_key }.try(:with, bindings)
          bindings[:controller] ? (action.try(:visible?) && action || nil) : action
        end

        def collection(key, parent_class = :base, &block)
          add_action key, parent_class, :collection, &block
        end

        def member(key, parent_class = :base, &block)
          add_action key, parent_class, :member, &block
        end

        def root(key, parent_class = :base, &block)
          add_action key, parent_class, :root, &block
        end

        def add_action(key, parent_class, parent, &block)
          a = "RailsAdmin::Config::Actions::#{parent_class.to_s.camelize}".constantize.new
          a.instance_eval(%(
            #{parent} true
            def key
              :#{key}
            end
          ))
          add_action_custom_key(a, &block)
        end

        def reset
          @@actions = nil
        end

        def register(name, klass = nil)
          if klass.nil? && name.is_a?(Class)
            klass = name
            name = klass.to_s.demodulize.underscore.to_sym
          end

          instance_eval %{
            def #{name}(&block)
              action = #{klass}.new
              add_action_custom_key(action, &block)
            end
          }
        end

        def init_actions!
          require_rel 'actions'
          base_actions.each do |action|
            klass = "RailsAdmin::Config::Actions::#{action.camelize}".constantize
            register(klass)
          end
        end

      private

        def add_action_custom_key(action, &block)
          action.instance_eval(&block) if block
          @@actions ||= []
          if action.custom_key.in?(@@actions.collect(&:custom_key))
            raise "Action #{action.custom_key} already exists. Please change its custom key."
          else
            @@actions << action
          end
        end

        def base_actions
          @_base_actions ||= Dir[RailsAdmin::Engine.root.join('lib', 'rails_admin', 'config', 'actions', '*.rb')].map do |action|
            action.match(/\/(\w+)\.rb$/)[1]
          end.except('base')
        end
      end
    end
  end
end
