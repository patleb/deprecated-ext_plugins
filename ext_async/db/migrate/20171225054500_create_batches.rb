class CreateBatches < ActiveRecord::Migration[5.1]
  def change
    create_table :batches do |t|
      t.text     :url,      null: false
      t.boolean  :priority, null: false, default: false
      t.datetime :run_at,   null: false

      t.timestamps null: false
    end

    add_index :batches, [:priority, :run_at], name: "index_batches_on_priority_run_at", order: { priority: :desc }
  end
end
