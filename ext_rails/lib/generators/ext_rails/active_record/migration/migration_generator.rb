require 'rails/generators/active_record/migration/migration_generator'

ActiveRecord::Generators::MigrationGenerator.class_eval do
  def self.migration_lookup_at(dirname)
    now = Time.now.utc.strftime("%Y%m%d%H%M%S")
    super.reject{ |file| file.to_s.match(/\/(\d+)_\w+.rb$/)[1] > now }
  end
end
