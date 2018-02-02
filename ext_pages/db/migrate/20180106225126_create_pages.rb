class CreatePages < ActiveRecord::Migration[5.1]
  def change
    create_table :pages do |t|
      t.belongs_to  :page,          foreign_key: { on_delete: :restrict }
      t.string      :type,          null: false
      t.text        :view_path
      t.belongs_to  :level_parent,  index: false
      t.ltree       :level
      t.integer     :level_slot,    null: false, default: 0
      t.datetime    :published_at
      t.jsonb       :data,          null: false, default: {}
      t.integer     :lock_version,  null: false, default: 0

      t.timestamps null: false
    end

    add_index :pages, [:view_path, :type]
    add_index :pages, [:level_parent_id, :level_slot], unique: true
    add_index :pages, :level, using: :gist
    add_index :pages, :data, using: :gin
  end
end
