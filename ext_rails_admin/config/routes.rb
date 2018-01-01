RailsAdmin::Engine.routes.draw do
  controller 'main' do
    if RailsAdmin.config.root_model_name
      root action: :index, model_name: RailsAdmin.config.root_model_name.constantize.to_admin_param
    end
    RailsAdmin::Config::Actions.all(:root).each { |action| match "/#{action.route_fragment}", action: action.action_name, as: action.action_name, via: action.http_methods }
    scope ':model_name' do
      RailsAdmin::Config::Actions.all(:collection).each { |action| match "/#{action.route_fragment}", action: action.action_name, as: action.action_name, via: action.http_methods }
      post '/bulk_action', action: :bulk_action, as: 'bulk_action'
      scope ':id' do
        RailsAdmin::Config::Actions.all(:member).each { |action| match "/#{action.route_fragment}", action: action.action_name, as: action.action_name, via: action.http_methods }
      end
    end
  end
end