class SettingsYml::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/settings_yml.rake'
  end
end
