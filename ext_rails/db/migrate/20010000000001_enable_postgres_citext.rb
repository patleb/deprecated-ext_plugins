class EnablePostgresCitext < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'citext'
  end
end
