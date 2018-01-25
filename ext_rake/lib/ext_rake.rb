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
  autoload :Addons, 'tasks/ext_rake/addons'
  autoload :Backup, 'tasks/ext_rake/backup'
  autoload :Openvpn, 'tasks/ext_rake/openvpn'
  autoload :Restore, 'tasks/ext_rake/restore'
end