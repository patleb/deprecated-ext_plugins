class ExtPundit::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/pundit.rake'
  end
end
