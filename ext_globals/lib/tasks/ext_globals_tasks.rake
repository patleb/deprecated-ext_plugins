namespace :ext_globals do
  desc 'cleanup'
  task :cleanup, [:lock] => :environment do |t, args|
    Global.cleanup lock: args[:lock].to_b
  end
end
