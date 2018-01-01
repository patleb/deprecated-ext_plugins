module RailsAdmin
  class ModelNotFound < ::StandardError
  end

  class ObjectNotFound < ::StandardError
  end

  class ActionNotAllowed < ::StandardError
  end

  class TooManyRows < ::StandardError
  end

  class ApplicationController < Config.parent_controller.constantize
    # TODO https://github.com/oivoodoo/devise_masquerade
    prepend_before_action :authenticate_user! if defined? Devise
    protect_from_forgery with: :exception, prepend: true

    before_action :_authorize!
    # TODO https://github.com/sfcgeorge/rails_admin-state_machines-audit_trail
    before_action :_audit!
    after_action :_versionize

    helper_method :_get_app_name

    attr_reader :object, :model_config, :abstract_model, :authorization_adapter

    def get_model
      @model_name = to_model_name(params[:model_name])
      raise(RailsAdmin::ModelNotFound) unless (@abstract_model = RailsAdmin::AbstractModel.new(@model_name))
      raise(RailsAdmin::ModelNotFound) if (@model_config = @abstract_model.config).excluded?
      @properties = @abstract_model.properties
    end

    def get_object
      raise(RailsAdmin::ObjectNotFound) unless (@object = @abstract_model.get(params[:id]))
    end

    def get_title
      @title = "#{@abstract_model.try(:pretty_name) || @page_name} | #{_get_app_name}"
    end

    def to_model_name(param)
      param.split(RailsAdmin::Config::NAMESPACE_SEPARATOR).collect(&:camelize).join('::')
    end

  private

    def current_user
      nil
    end unless defined? Devise

    def _get_app_name
      @app_name ||= (RailsAdmin.config.main_app_name.is_a?(Proc) ? instance_eval(&RailsAdmin.config.main_app_name) : RailsAdmin.config.main_app_name) || 'Rails Admin'
    end

    def _authorize!
      instance_eval(&RailsAdmin::Config.authorize_with)
    end

    def _audit!
      instance_eval(&RailsAdmin::Config.audit_with)
    end

    def _versionize
      response.set_header('X-PJAX-VERSION', application_version)
    end

    def rails_admin_controller?
      true
    end
  end
end
