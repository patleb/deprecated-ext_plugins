class EnablePostgresLtree < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'ltree'
  end
end
