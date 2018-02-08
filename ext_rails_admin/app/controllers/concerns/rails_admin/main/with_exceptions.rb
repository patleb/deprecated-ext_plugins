module RailsAdmin
  module Main
    module WithExceptions
      extend ActiveSupport::Concern

      included do
        rescue_from RailsAdmin::ObjectNotFound do
          flash[:error] = I18n.t('admin.flash.object_not_found', model: @model_name, id: params[:id])
          params[:action] = 'index'
          @status_code = :not_found
          serve_action :index
        end

        rescue_from RailsAdmin::ModelNotFound do
          unless defined?(Devise) && @model_name == 'Users'
            flash[:error] = I18n.t('admin.flash.model_not_found', model: @model_name)
          end
          redirect_to dashboard_path
        end

        rescue_from Pundit::NotAuthorizedError do
          flash[:error] = I18n.t('admin.flash.not_allowed')
          redirect_to dashboard_path
        end if defined? Pundit

        rescue_from ActiveRecord::InvalidForeignKey do
          @object.errors.add :base, :dependency_constraints
          handle_save_error params[:action]
        end

        rescue_from ActiveRecord::StaleObjectError do
          @object.errors.add :base, :already_modified_html
          @object.lock_version = @object.lock_version_was
          handle_save_error :edit
        end

        rescue_from RailsAdmin::TooManyRows do |exception|
          response.headers['X-Status-Reason'] = exception.message
          head 413
        end
      end
    end
  end
end
