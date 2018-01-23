class EnablePostgresDblink < ActiveRecord::Migration[5.1]
  def change
    if Rails.env.development? || Rails.env.test?
      enable_extension 'dblink'
    end
  end
end
