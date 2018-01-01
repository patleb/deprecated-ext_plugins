namespace :secrets do
  desc 'upload secrets.yml to server'
  task :push do
    on release_roles fetch(:bundle_roles) do
      yml = YAML.load(ERB.new(Pathname.new(fetch(:app_root)).join('config', 'secrets.yml').read).result)
      secrets = (yml['shared'] || {}).merge!(yml[fetch(:stage).to_s] || {})
      fetch(:secrets_excluded).each do |name|
        secrets.delete name
      end
      yml = StringIO.new({ fetch(:stage).to_s => secrets }.to_yaml.sub(/^---\n/, ''))
      upload! yml, "#{shared_path.join('config', 'secrets.yml')}"
    end
  end
end
