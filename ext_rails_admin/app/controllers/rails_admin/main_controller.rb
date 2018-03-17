# TODO shrine + que

module RailsAdmin
  class MainController < RailsAdmin::ApplicationController
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper
    include RailsAdmin::ApplicationHelper
    include RailsAdmin::MainHelper

    RailsAdmin::Config::Actions.all.each do |action|
      include "RailsAdmin::Main::#{action.action_name.to_s.camelize}Action".constantize
    end

    layout :get_layout

    before_action :get_model, except: RailsAdmin::Config::Actions.all(:root).collect(&:action_name)
    before_action :get_object, only: RailsAdmin::Config::Actions.all(:member).collect(&:action_name)
    before_action :get_title
    before_action :check_for_cancel
    before_action :after_redirected
    before_action :prepare_action, except: :bulk_action
    around_action :use_model_time_zone

    def bulk_action
      serve_action(params[:bulk_action].to_sym) if params[:bulk_action].in?(RailsAdmin::Config::Actions.all(controller: self, abstract_model: @abstract_model).select(&:bulkable?).collect(&:route_fragment))
    end

    def list_entries(model_config = @model_config, auth_scope_key = :index, additional_scope = get_association_scope_from_params, pagination = !(params[:associated_collection] || params[:all] || params[:bulk_ids]))
      scope = model_config.abstract_model.scoped
      if auth_scope = @authorization_adapter && @authorization_adapter.query(auth_scope_key, model_config.abstract_model)
        scope = scope.merge(auth_scope)
      end
      scope = scope.instance_eval(&additional_scope) if additional_scope
      get_collection(model_config, scope, pagination)
    end

    def redirect_to(*args)
      super
      session[:redirected] = (status == 302)
    end

    private

    def use_model_time_zone
      if (tz = @model_config.time_zone)
        Time.use_zone(tz) do
          yield
        end
      else
        yield
      end
    end

    def prepare_action(name = nil)
      action_config = RailsAdmin::Config::Actions.find(name || action_name.to_sym)
      @authorization_adapter.try(:authorize, action_config.authorization_key, @abstract_model, @object)
      @action = action_config.with(controller: self, abstract_model: @abstract_model, object: @object)
      fail(ActionNotAllowed) unless @action.enabled?
      @page_name = wording_for(:title)
    end

    def serve_action(name)
      prepare_action(name)
      send(name)
    end

    def get_layout
      "rails_admin/#{request.headers['X-PJAX'] ? 'pjax' : 'application'}"
    end

    def back_or_index
      return_to = params[:return_to]
      if return_to.presence
        if return_to.include?(request.host)
          if return_to.exclude?(request.fullpath.sub(/\?.*/, ''))
            return return_to
          end
        end
      end
      index_path
    end

    def get_sort_hash(model_config)
      # TODO https://github.com/sferik/rails_admin/issues/2346
      abstract_model = model_config.abstract_model
      params[:sort] = params[:sort_reverse] = nil unless model_config.list.fields.collect { |f| f.name.to_s }.include? params[:sort]
      params[:sort] ||= model_config.list.sort_by.to_s
      params[:sort_reverse] ||= 'false'

      field = model_config.list.fields.detect { |f| f.name.to_s == params[:sort] }
      column = begin
        if field.nil? || (sortable = field.sortable) == true # use params[:sort] on the base table
          %("#{abstract_model.table_name}".#{ActiveRecord::Base.connection.quote_column_name(params[:sort])})
        elsif sortable == false # use default sort, asked field is not sortable
          %("#{abstract_model.table_name}"."#{model_config.list.sort_by}")
        elsif (sortable.is_a?(String) || sortable.is_a?(Symbol)) && sortable.to_s.include?('.') # just provide sortable, don't do anything smart
          sortable
        elsif sortable.is_a?(Hash) # just join sortable hash, don't do anything smart
          %("#{sortable.first.join('"."')}")
        elsif field.association? # use column on target table
          %("#{field.associated_model_config.abstract_model.table_name}"."#{sortable}")
        else # use described column in the field conf.
          %("#{abstract_model.table_name}"."#{sortable}")
        end
      end

      reversed_sort = (field ? field.sort_reverse? : model_config.list.sort_reverse?)
      {sort: column, sort_reverse: (params[:sort_reverse] == reversed_sort.to_s)}
    end

    def redirect_to_on_success(name = @model_config.label, options = {})
      notice = I18n.t('admin.flash.successful', name: name, action: I18n.t("admin.actions.#{@action.key}.done"))
      if params[:_add_another]
        redirect_to new_path(return_to: params[:return_to]), options.merge(flash: {success: notice})
      elsif params[:_add_edit]
        redirect_to edit_path(id: @object.id, return_to: params[:return_to]), options.merge(flash: {success: notice})
      else
        redirect_to back_or_index, options.merge(flash: {success: notice})
      end
    end

    def visible_fields(action, model_config = @model_config)
      model_config.send(action).with(controller: self, view: view_context, object: @object).visible_fields
    end

    def sanitize_params_for!(action, model_config = @model_config, target_params = params[@abstract_model.param_key])
      return unless target_params.present?
      fields = visible_fields(action, model_config)
      allowed_methods = fields.collect(&:allowed_methods).flatten.uniq.collect(&:to_s) << 'id' << '_destroy'
      fields.each { |field| field.parse_input(target_params) }
      target_params.slice!(*allowed_methods)
      target_params.permit! if target_params.respond_to?(:permit!)
      fields.select(&:nested_form).each do |association|
        children_params = association.multiple? ? target_params[association.method_name].try(:values) : [target_params[association.method_name]].compact
        (children_params || []).each do |children_param|
          sanitize_params_for!(:nested, association.associated_model_config, children_param)
        end
      end
    end

    def handle_save_error(whereto, name = @model_config.label)
      flash.now[:error] = I18n.t('admin.flash.error', name: name, action: I18n.t("admin.actions.#{@action.key}.done").html_safe).html_safe
      flash.now[:error] += %(<br>- #{@object.errors.full_messages.join('<br>- ')}).html_safe

      if params[:inline].to_b
        render json: { flash: { error: flash.now[:error] } }, status: :not_acceptable
      else
        respond_to do |format|
          format.html { render whereto, status: :not_acceptable }
          format.js { render whereto, layout: false, status: :not_acceptable }
        end
      end
    end

    def check_for_cancel
      redirect_to(back_or_index, notice: I18n.t('admin.flash.noaction')) if params[:_continue] || (params[:bulk_action] && !params[:bulk_ids])
    end

    def after_redirected
      if session[:redirected]
        session[:redirected] = false
        if request.headers['X-PJAX'].to_b
          response.headers['X-PJAX-URL'] = request.url
        end
      end
    end

    def get_collection(model_config, scope, pagination)
      fields = model_config.list.fields
      eager_load = fields.select{ |f| f.try(:eager_load?) }.map{ |f| f.association.name }
      left_joins = fields.select{ |f| f.try(:left_joins?) }.map{ |f| f.association.name }
      options = {}
      options.merge!(include: eager_load) unless eager_load.blank?
      options.merge!(left_joins: left_joins) unless left_joins.blank?
      options.merge!(distinct: true) if fields.any?{ |f| f.try(:distinct?) }
      options.merge!(get_sort_hash(model_config))
      # TODO convert to keyset pagination --> still a bug when :first isn't unique
      # https://github.com/glebm/order_query
      if pagination
        page = (params[:page] || 1).to_i
        if page > 1 && (first_item = params[:first]).present?
          operator = options[:sort_reverse].to_b ? '>=' : '<='
          scope = scope.where("#{options[:sort]} #{operator} :first_item", first_item: first_item)
        end
        options.merge!(page: page, per: (params[:per] || model_config.list.items_per_page))
      end
      options.merge!(query: params[:query]) if params[:query].present?
      options.merge!(filters: params[:f]) if params[:f].present?
      options.merge!(bulk_ids: params[:bulk_ids]) if params[:bulk_ids]
      model_config.abstract_model.all(options, scope)
    end

    def get_association_scope_from_params
      return nil unless params[:associated_collection].present?
      source_abstract_model = RailsAdmin::AbstractModel.new(to_model_name(params[:source_abstract_model]))
      source_model_config = source_abstract_model.config
      source_object = source_abstract_model.get(params[:source_object_id])
      action = params[:current_action].in?(%w(create update)) ? params[:current_action] : 'edit'
      @association = source_model_config.send(action).fields.detect { |f| f.name == params[:associated_collection].to_sym }.with(controller: self, object: source_object)
      @association.associated_collection_scope
    end
  end
end
