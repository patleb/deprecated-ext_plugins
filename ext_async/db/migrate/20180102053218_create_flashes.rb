class CreateFlashes < ActiveRecord::Migration[5.1]
  def change
    create_table :flashes do |t|
      t.text :session_id, null: false
      t.text :request_id, null: false
      t.json :messages,   null: false, default: {}

      t.timestamps null: false
    end

    add_index :flashes, [:session_id, :request_id], { unique: true }
  end
end
