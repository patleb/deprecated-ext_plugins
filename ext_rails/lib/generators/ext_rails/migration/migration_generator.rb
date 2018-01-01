require 'rails/generators/rails/migration/migration_generator'
require 'generators/ext_rails/active_record/migration/migration_generator'

module ExtRails
  class MigrationGenerator < ::Rails::Generators::MigrationGenerator
  end
end
