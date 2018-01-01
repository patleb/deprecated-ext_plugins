namespace :ext_throttler do
  desc 'clear all'
  task :clear_all, [:prefix] => :environment do |t, args|
    key =
      if (prefix = args[:prefix]).present?
        /^#{ExtThrottler::PREFIX}:#{prefix}/
      else
        /^#{ExtThrottler::PREFIX}:/
      end
    Global.delete_matched key, lock: true
  end
end
