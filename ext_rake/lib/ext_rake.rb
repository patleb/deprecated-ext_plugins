require "require_all"
require 'rubygems/package'
require 'colorize'
require 'dotiw'
require 'open3'
require 'optparse'
require 'ext_aws_sdk'
require "ext_mail"
require "ext_rake/configuration"
require 'ext_rake/railtie' if defined?(Rails)

module ActiveTask
  autoload :Base, 'ext_rake/active_task/base'
end

module ExtRake
  autoload :Backup,     'tasks/ext_rake/backup'
  autoload :Raise,      'tasks/ext_rake/raise'
  autoload :Openvpn,    'tasks/ext_rake/openvpn'
  autoload :Partition,  'tasks/ext_rake/partition'
  autoload :Pg,         'tasks/ext_rake/pg'
  autoload :Pgslice,    'tasks/ext_rake/pgslice'
  autoload :Restore,    'tasks/ext_rake/restore'

  autoload :BackupPartition,  'tasks/ext_rake/backup/partition'

  autoload :PgDropAll,  'tasks/ext_rake/pg/drop_all'
  autoload :PgDump,     'tasks/ext_rake/pg/dump'
  autoload :PgRestore,  'tasks/ext_rake/pg/restore'
  autoload :PgSqlite,   'tasks/ext_rake/pg/sqlite'
  autoload :PgTruncate, 'tasks/ext_rake/pg/truncate'

  autoload :RestoreArchive,   'tasks/ext_rake/restore/archive'
  autoload :RestorePostgres,  'tasks/ext_rake/restore/postgres'
  autoload :RestoreSync,      'tasks/ext_rake/restore/sync'

  autoload :BackupGit,          'tasks/ext_rake/addons/backup_git'
  autoload :CleanUpApplication, 'tasks/ext_rake/addons/clean_up_application'
  autoload :SendMail,           'tasks/ext_rake/addons/send_mail'
  autoload :UpdateApplication,  'tasks/ext_rake/addons/update_application'
  autoload :UpdateVpnIp,        'tasks/ext_rake/addons/update_vpn_ip'
end
