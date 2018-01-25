ExtMobility.configure do |config|
  config.polymorphic_tables.concat(%w(
    pages
    contents
  ))
end
