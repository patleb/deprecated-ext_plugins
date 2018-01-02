class CreateFlashes < ActiveRecord::Migration[5.1]
  def change
    create_table :flashes, id: false do |t|
      t.primary_key :id, :text
      t.json        :messages, null: false, default: {}

      t.timestamps null: false
    end
  end
end
