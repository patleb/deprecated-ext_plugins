# TODO https://github.com/Fullscreen/aws-rotate-key

namespace :settings_yml do
  desc "encrypt file or ENV['DATA']"
  task :encrypt, [:env, :file] do |t, args|
    raise 'argument [:env] must be specified' unless (ENV['RAILS_ENV'] = args[:env])
    ENV['RAILS_APP'] ||= ENV['APP']

    if ENV['DATA'].present?
      puts SettingsYml.encrypt(ENV['DATA'])
    else
      puts SettingsYml.encrypt(Pathname.new(args[:file]).expand_path.read)
    end
  end

  desc "decrypt key and optionally output to file"
  task :decrypt, [:env, :key, :file] do |t, args|
    raise 'argument [:env] must be specified' unless (ENV['RAILS_ENV'] = args[:env])
    ENV['RAILS_APP'] ||= ENV['APP']

    SettingsYml.with_clean_env
    if args[:file].present?
      File.open(Pathname.new(args[:file]).expand_path, 'w'){ |f| f.print SettingsYml[args[:key]] }
      puts "[:#{args[:key]}] key written to file [#{args[:file]}]"
    else
      value =
        if ENV['DATA'].present?
          SettingsYml.decrypt(ENV['DATA'])
        else
          SettingsYml[args[:key]]
        end
      if ENV['ESCAPE'].to_b
        value = value.escape_newlines
      end
      if ENV['UNESCAPE'].to_b
        value = value.unescape_newlines
      end
      puts value
    end
  end

  desc 'escape file newlines'
  task :escape, [:file] do |t, args|
    puts Pathname.new(args[:file]).expand_path.read.escape_newlines
  end
end
