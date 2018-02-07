namespace :ext_rake do
  %w(
    backup_git
    clean_up_application
    send_mail
    update_application
    update_vpn_ip
  ).each do |name|
    desc name.tr('_', ' ')
    task name.to_sym => :environment do |t|
      "::ExtRake::#{name.camelize}".constantize.new(self, t).run
    end
  end

  desc '-- [options] Backup model'
  task :backup => :environment do |t|
    ExtRake::Backup.new(self, t).run
  end

  desc '-- [options] Restore Postgres model version'
  task :restore_postgres => :environment do |t|
    ExtRake::PostgresRestore.new(self, t).run
  end

  desc '-- [options] Restore Archive model version'
  task :restore_archive => :environment do |t|
    ExtRake::ArchiveRestore.new(self, t).run
  end

  desc '-- [options] Restore Sync directory'
  task :restore_sync => :environment do |t|
    ExtRake::SyncRestore.new(self, t).run
  end
end
