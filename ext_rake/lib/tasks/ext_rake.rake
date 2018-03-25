namespace :ext_rake do
  tasks = %w(
    backup
    backup_partition
    partition
    pg_drop_all
    pg_dump
    pg_restore
    pg_sqlite
    pg_truncate
    restore_postgres
    restore_archive
    restore_sync
  )

  addons = %w(
    backup_git
    clean_up_application
    send_mail
    update_application
    update_vpn_ip
  )

  (tasks + addons).each do |name|
    desc "-- [options] #{name.humanize}"
    task name.to_sym => :environment do |t|
      "::ExtRake::#{name.camelize}".constantize.new(self, t).run
    end
  end
end
