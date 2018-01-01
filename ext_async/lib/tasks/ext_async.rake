namespace :ext_async do
  desc '-- [options] Perform all batches'
  task :batches => :environment do |t|
    ExtAsync::Batches.new(self, t).run
  end
end
