class EnablePostgresCounterCache < ActiveRecord::Migration[5.1]
  def up
    # Example
    #
    # add_column        :accounts, :users_count, :integer, null: false, default: 0
    # add_counter_cache :accounts, :users_count, :users, :account_id
    #
    create_function_counter_cache
  end

  def down
    # Example
    #
    # remove_counter_cache :accounts, :users_count, :users
    # remove_column        :accounts, :users_count
    #
    drop_function_counter_cache
  end
end
