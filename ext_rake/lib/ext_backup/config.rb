# encoding: utf-8

require 'ext_rake/configuration'

SettingsYml.with_clean_env

root_path ExtRake.config.backup_dir

Logger.configure do
  logfile.enabled = false
end

Storage::Local.defaults do |local|
  local.path = ExtRake.config.backup_local_path
end

Storage::S3.defaults do |s3|
  s3.access_key_id     = ExtRake.config.s3_access_key_id
  s3.secret_access_key = ExtRake.config.s3_secret_access_key
  s3.region            = ExtRake.config.s3_region
  s3.bucket            = ExtRake.config.s3_bucket
  s3.path              = ExtRake.config.backup_s3_path
  s3.storage_class     = :standard_ia
end

Syncer::RSync::Local.defaults do |local|
  local.path   = ExtRake.config.backup_local_path
  local.mirror = true
end

Syncer::Cloud::S3.defaults do |s3|
  s3.access_key_id     = ExtRake.config.s3_access_key_id
  s3.secret_access_key = ExtRake.config.s3_secret_access_key
  s3.region            = ExtRake.config.s3_region
  s3.bucket            = ExtRake.config.s3_bucket
  s3.path              = ExtRake.config.backup_s3_path
  s3.mirror            = true
end

Notifier::Mail.defaults do |mail|
  mail.on_success           = false
  mail.on_warning           = false
  mail.on_failure           = true

  mail.from                 = SettingsYml[:mail_from]
  mail.to                   = SettingsYml[:mail_to]
  mail.address              = SettingsYml[:mail_address]
  mail.port                 = SettingsYml[:mail_port]
  mail.domain               = SettingsYml[:mail_domain]
  mail.user_name            = SettingsYml[:mail_user_name]
  mail.password             = SettingsYml[:mail_password]
  mail.authentication       = "plain"
  mail.encryption           = :starttls
end

Database::PostgreSQL.defaults do |db|
  db.name               = SettingsYml[:db_database]
  db.username           = SettingsYml[:db_username]
  db.password           = SettingsYml[:db_password]
  db.host               = SettingsYml[:db_host]
  db.port               = 5432
  db.additional_options = %(--clean --no-owner --no-acl)
end

preconfigure 'ExtRakeBackup' do
  compress_with Gzip

  notify_by Mail

  split_into_chunks_of 250 # MB
end

preconfigure 'ExtRakeSync' do
  notify_by Mail
end

ExtRakeBackup.new(:app_logs, 'Backup application logs') do
  store_with ExtRake.config.storage

  archive :logs do |archive|
    archive.add ExtRake.config.log_dir
  end
end

ExtRakeBackup.new(:sys_logs, 'Backup system logs') do
  store_with ExtRake.config.storage

  archive :logs do |archive|
    archive.use_sudo
    archive.add '/var/log/'
  end
end

Model.new(:meta, 'Backup meta directory') do
  before do
    unless Dir.exist? ExtRake.config.backup_meta_dir
      FileUtils.mkdir_p ExtRake.config.backup_meta_dir
    end
  end

  sync_with ExtRake.config.syncer do |syncer|
    syncer.mirror = false

    syncer.directories do |directory|
      directory.add ExtRake.config.backup_meta_dir
      # TODO doesn't seem to work
      directory.exclude /\/(?!#{ExtRake.config.backup_model})\//
    end
  end

  notify_by Mail
end
