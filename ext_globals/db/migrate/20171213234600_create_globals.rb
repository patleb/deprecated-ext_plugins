class CreateGlobals < ActiveRecord::Migration[5.1]
  def change
    create_table :globals, id: false do |t|
      t.primary_key :id, :text
      t.boolean     :expires,   null: false, default: false
      t.integer     :type,      null: false, default: 0
      t.text        :text
      t.text        :texts,     array: true
      t.json        :json
      t.json        :jsons,     array: true
      t.boolean     :boolean
      t.boolean     :booleans,  array: true
      t.bigint      :integer
      t.bigint      :integers,  array: true
      t.decimal     :decimal
      t.decimal     :decimals,  array: true
      t.datetime    :datetime
      t.datetime    :datetimes, array: true
      t.interval    :interval
      t.interval    :intervals, array: true

      t.timestamps null: false
    end

    add_index :globals, [:expires, :updated_at], name: "index_globals_on_expires_updated_at", order: { expires: :desc }
  end
end
