namespace :whenever do
  desc 'Create log/cron.log'
  task :create_cron_log do
    on release_roles fetch(:whenever_roles) do
      within shared_path do
        execute :mkdir, '-p', 'log'
        execute :touch, File.join('log', 'cron.log')
      end
    end
  end

  desc 'Push every_minutes.sh cron script'
  task :push_every_minute do
    on release_roles fetch(:whenever_roles) do
      (SettingsYml[:batch_workers]&.to_i || 1).times.each do |i|
        invoke! 'template:push', 'every_minute.sh', release_path.join('bin', "every_minute_#{i}.sh")
      end
      fetch(:whenever_batch_scripts).each do |script|
        invoke! 'template:push', "every_minute/#{script}.sh", release_path.join('bin', 'every_minute', "#{script}.sh")
      end
    end
  end
  after 'git:create_release', 'whenever:push_every_minute'
end
