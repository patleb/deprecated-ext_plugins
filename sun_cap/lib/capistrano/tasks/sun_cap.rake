namespace :sun_cap do
  desc 'output capistrano config'
  task :config do
    ENV['RAILS_ROOT'] = Dir.pwd
    env = Capistrano::Configuration.env
    values = env.variables.instance_values['values'].each_with_object({}) do |(key, value), memo|
      value = value.call if value.respond_to?(:call)
      memo[key] = value
    end
    output = values.slice(*SunCap.config.capistrano).merge!(
      port: values[:ssh_options].try(:[], :port) || values[:port],
      pkey: values[:ssh_options].try(:[], :keys).try(:first),
    ).each_with_object('') do |(key, value), output|
      output << key.to_s << ' ' << value.to_s << "\n"
    end
    puts output
  end
end
