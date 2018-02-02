require "ext_pages/configuration"
require "ext_pages/pages_yml"

module ExtPages
  class Engine < ::Rails::Engine
    require 'ext_rails'
    require 'ext_mobility'

    initializer 'ext_pages.append_migrations' do |app|
      unless ExtPages.config.skip_migrations
        unless app.root.to_s.match(root.to_s)
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end

    config.after_initialize do |app|
      app.routes.prepend do
        PagesYml.load.pages_types.each do |page, _type|
          get page => 'pages#show', defaults: { _page: page }
        end

        get "/:slug/#{Page::Simple::URL_SEGMENT}/:hashid" => 'pages#show', as: :page
      end
    end
  end
end
