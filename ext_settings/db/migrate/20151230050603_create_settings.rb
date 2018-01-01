class CreateSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :settings, id: false do |t|
      t.primary_key :id, :string
      t.text        :value
      t.string      :description
      t.integer     :lock_version, null: false, default: 0

      t.timestamps null: false
    end
  end
end
