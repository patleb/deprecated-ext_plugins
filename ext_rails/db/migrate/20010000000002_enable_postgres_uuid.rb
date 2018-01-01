class EnablePostgresUuid < ActiveRecord::Migration[5.1]
  def change
    # Example
    #
    # t.primary_key :id, :uuid, default: 'uuid_generate_v1mc()'
    #
    enable_extension 'uuid-ossp'
  end
end
