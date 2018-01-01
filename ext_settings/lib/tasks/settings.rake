namespace :settings do
  desc 'rename setting key'
  task :rename, [:old, :new] => :environment do |t, args|
    Setting.rename(args[:old], args[:new])
  end

  desc 'update setting value'
  task :update, [:key, :value] => :environment do |t, args|
    Setting.modify(args[:key], args[:value])
  end
end
