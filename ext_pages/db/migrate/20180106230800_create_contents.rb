class CreateContents < ActiveRecord::Migration[5.1]
  def change
    create_table :contents do |t|
      t.belongs_to  :page,          null: false, foreign_key: { on_delete: :restrict }
      t.string      :type,          null: false
      t.string      :name,          null: false, default: ''
      t.integer     :position,      null: false, default: 0
      t.jsonb       :data,          null: false, default: {}
      t.integer     :lock_version,  null: false, default: 0

      t.timestamps null: false
    end

    add_index :contents, [:page_id, :name, :position], unique: true
    add_index :contents, :data, using: :gin
  end
end
