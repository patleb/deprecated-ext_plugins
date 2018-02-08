namespace :files do
  desc 'Download remote file(s)'
  task :download, [:src, :dst] do |t, args|
    on release_roles :all do |host|
      download_file(host, args[:src], args[:dst])
    end
  end

  desc 'Upload local file(s)'
  task :upload, [:src, :dst, :user] do |t, args|
    on release_roles :all do |host|
      if (user = args[:user]).present?
        user = (user == 'user') || user.to_b
      end
      upload_file(host, args[:src], args[:dst], user: user)
    end
  end

  desc 'Import public files'
  task :pull do
    on release_roles :all do |host|
      fetch(:files_public_dirs).each do |folder|
        get_files host, 'public', folder
      end
    end
  end

  desc 'Export public files'
  task :push do
    on release_roles :all do |host|
      fetch(:files_public_dirs).each do |folder|
        send_files host, 'public', folder
      end
    end
  end

  namespace :private do
    desc 'Import private files'
    task :pull do
      on release_roles :all do |host|
        fetch(:files_private_dirs).each do |folder|
          get_files host, 'private', folder
        end
      end
    end

    desc 'Export private files'
    task :push do
      on release_roles :all do |host|
        fetch(:files_private_dirs).each do |folder|
          send_files host, 'private', folder
        end
      end
    end
  end
end
