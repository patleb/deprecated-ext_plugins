namespace :authorized_keys do
  desc 'push deployer authorized_keys'
  task :push do
    on release_roles :all do
      execute SunCap.build_authorized_keys
    end
  end

  desc 'add public key to authorized_keys'
  task :add, [:path] do |t, args|
    on release_roles :all do
      if ENV['KEY'].present?
        key = ENV['KEY']
      else
        abort("public key doesn't exist!") unless File.exist?(args[:path])
        key = File.open(args[:path], &:readline).strip
      end
      execute Sh.concat('~/.ssh/authorized_keys', key, unique: true)
    end
  end

  desc 'remove public key to authorized_keys'
  task :remove, [:path] do |t, args|
    on release_roles :all do
      if ENV['KEY'].present?
        key = ENV['KEY']
      else
        abort("public key doesn't exist!") unless File.exist?(args[:path])
        key = File.open(args[:path], &:readline).strip
      end
      execute Sh.delete_line!('~/.ssh/authorized_keys', key)
    end
  end
end
