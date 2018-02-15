module ExtRake
  module Psql
    extend ActiveSupport::Concern

    class_methods do
      def psql_url
        "postgresql://#{SettingsYml[:db_username]}:#{SettingsYml[:db_password]}@#{SettingsYml[:db_host]}:5432/#{SettingsYml[:db_database]}"
      end
    end
  end
end
