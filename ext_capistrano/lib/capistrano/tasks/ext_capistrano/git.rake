# https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html
# https://forums.aws.amazon.com/thread.jspa?threadID=228206

namespace :git do
  desc 'Update new git repo url'
  task :remote_set_url do
    on release_roles :all do
      within repo_path do
        execute :git, 'remote', 'set-url', 'origin', fetch(:repo_url)
      end
    end
  end

  desc 'Set AWS git config'
  task :set_aws_git_config do
    on release_roles :all do
      if fetch(:repo_url).include? 'git-codecommit'
        private_key = "/home/deployer/.ssh/id_rsa"
        unless remote_file_exist? private_key
          capture Sh.bash "echo -e '#{SettingsYml[:admin_private_key]}' > #{private_key}"
          execute :sudo, :chmod, 600, private_key
        end

        aws_git_config = "/home/deployer/.ssh/config"
        unless remote_file_exist? aws_git_config
          git_config = <<~FILE
            Host git-codecommit.*.amazonaws.com
              User #{SettingsYml[:git_public_key_id]}
              IdentityFile #{private_key}
          FILE
          capture Sh.bash "echo -e '#{git_config}' > #{aws_git_config}"
          execute :sudo, :chmod, 600, aws_git_config
        end
      end
    end
  end
  before 'git:check', 'git:set_aws_git_config'
end
