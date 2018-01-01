module ExtCapistrano
  module FileHelper
    def remote_file_exist?(full_path, sudo: false)
      cmd =
        if sudo
          %{if sudo test -e #{full_path}; then echo "true"; fi}
        else
          %{if [[ -e #{full_path} ]]; then echo "true"; fi}
        end
      capture(cmd).to_b
    end

    def send_files(server, root, folder)
      run_locally { execute "rsync --progress -rutzvh -e 'ssh -p #{fetch(:port, 22)}' #{root}/#{folder} #{server.user}@#{server.hostname}:#{shared_path}/#{root}/" }
    end

    def get_files(server, root, folder)
      run_locally { execute "rsync --progress -rutzvh -e 'ssh -p #{fetch(:port, 22)}' #{server.user}@#{server.hostname}:#{shared_path}/#{root}/#{folder} ./#{root}/" }
    end

    def upload_file(server, source, destination)
      run_locally { execute "rsync --rsync-path='sudo rsync' -azvh -e 'ssh -p #{fetch(:port, 22)}' '#{source}' deployer@#{server.hostname}:#{destination}" }
    end

    def download_file(server, source, destination)
      run_locally { execute "rsync --rsync-path='sudo rsync' -azvh -e 'ssh -p #{fetch(:port, 22)}' deployer@#{server.hostname}:#{source} '#{destination}'" }
    end

    def upload_erb(server, source, destination)
      compile_erb(source)
      upload_file(server, source, destination)
      FileUtils.rm_f source
    end

    def compile_erb(source)
      FileUtils.mkdir_p File.dirname(source)
      File.open(source, 'w') do |f|
        source_erb = "#{source}.erb"

        unless File.exist? source_erb
          source_erb = ExtCapistrano.root.join(source_erb)
        end

        f.puts ERB.new(File.read(source_erb), nil, '-').result
      end
    end
  end
end
