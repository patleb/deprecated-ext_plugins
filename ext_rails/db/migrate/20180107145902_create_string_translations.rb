class CreateStringTranslations < ActiveRecord::Migration[5.1]

  def change
    create_table :mobility_string_translations do |t|
      t.string  :locale
      t.string  :key
      t.string  :value
      t.integer :translatable_id
      t.string  :translatable_type
      t.timestamps
    end
    add_index :mobility_string_translations, [:translatable_id, :translatable_type, :locale, :key],
      name: :index_mobility_string_translations_on_keys, unique: true
    add_index :mobility_string_translations, [:translatable_type, :locale, :key, :value],
      name: :index_mobility_string_translations_on_query_keys
  end
end
