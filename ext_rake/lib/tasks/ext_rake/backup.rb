module Backup
  class Package
    attr_accessor :time, :chunk_suffixes
  end
end

module ExtRake
  class Backup < ExtRake.config.parent_task.constantize
    class InvalidModel < ::StandardError; end

    def self.steps
      [:run_backup]
    end

    def self.args
      {
        model:         ['--model=MODEL',        'Backup model'],
        sync:          ['--[no-]sync',          'Prevents running meta trigger'],
        s3_versionned: ['--[no-]s3-versionned', 'Same as sync option and specify if the s3 bucket is versionned'],
        sudo:          ['--[no-]sudo',          'Run as sudo'],
      }
    end

    def self.backup_gemfile
      'Backupfile'
    end

    def self.backup_root
      ExtRake.config.rails_root.join('config', 'backup')
    end

    def before_run
      super
      ExtRake.config.s3_versionned = options.s3_versionned
      @backup_failed = false
    end

    def sudo
      options.sudo ? 'rbenv sudo' : ''
    end

    protected

    def run_backup
      config_models = %w(app_logs sys_logs meta)
      unless config_models.include?(options.model.to_s) || self.class.backup_root.join('models', "#{options.model}.rb").exist?
        raise InvalidModel
      end

      backup_env = [
        "BUNDLE_GEMFILE=#{self.class.backup_gemfile}",
        "RAILS_ENV=#{ExtRake.config.rails_env}",
        "RAILS_APP=#{ExtRake.config.rails_app}",
        "RAILS_ROOT=#{ExtRake.config.rails_root}",
        "S3_VERSIONNED=#{options.s3_versionned}",
      ]
      backup_cmd = "bundle exec backup perform"
      backup_opt = [
        "--trigger #{options.model}#{',meta' unless options.sync || options.s3_versionned}",
        "--config_file #{self.class.backup_root.join('config.rb')}"
      ]

      Bundler.with_clean_env do
        sh [sudo, backup_env, backup_cmd, backup_opt].join(' ') do |ok, result|
          # on failure, an email should have been sent by the backup gem
          @backup_failed = !ok && result.exitstatus != 1
        end
      end
    end

    def meta_entry
      @_meta_entry ||= YAML.load(File.read(ExtRake.config.backup_meta_file(options.model))).first
    end
  end
end
