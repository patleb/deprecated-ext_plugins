class PgunitInstall < ActiveRecord::Migration[5.1]
  def up
    if Rails.env.development? || Rails.env.test?
      execute ExtRails::Engine.root.join('db/PGUnit.sql').read.strip_sql_script[1..-1]
    end
  end

  def down
    if Rails.env.development? || Rails.env.test?
      execute ExtRails::Engine.root.join('db/PGUnitDrop.sql').read.strip_sql_script
    end
  end
end
