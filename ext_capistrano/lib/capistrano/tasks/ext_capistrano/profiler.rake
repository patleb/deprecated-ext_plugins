namespace :profiler do
  desc 'Start Profiler'
  task :start do
    on release_roles :all do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :touch, 'tmp/profiler.txt'
          invoke('passenger:restart')
        end
      end
    end
  end

  desc 'Stop Profiler'
  task :stop do
    on release_roles :all do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :rm, '-f', 'tmp/profiler.txt'
          invoke('passenger:restart')
        end
      end
    end
  end
end
