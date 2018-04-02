class ServerRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :"server_#{Rails.env}"
end
