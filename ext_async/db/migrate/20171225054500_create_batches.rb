class CreateBatches < ActiveRecord::Migration[5.1]
  def change
    create_table :batches do |t|
      t.text     :url,    null: false
      t.boolean  :async,  null: false, default: false
      t.datetime :run_at, null: false

      t.timestamps null: false
    end

    add_index :batches, [:async, :run_at], name: "index_batches_on_async_run_at", order: { async: :desc }
  end
end
