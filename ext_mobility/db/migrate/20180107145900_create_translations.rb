class CreateTranslations < ActiveRecord::Migration[5.1]
  def change
    create_table :translations do |t|
      t.string  :locale
      t.string  :key
      t.text    :value
      t.belongs_to :translatable, polymorphic: true, index: false

      t.timestamps null: false
    end

    add_index :translations, [:translatable_id, :translatable_type, :key, :locale],
      name: :index_translations_on_keys, unique: true

    add_index :translations, [:value, :translatable_type, :key, :locale],
      name: :index_translations_on_query_keys
  end
end
