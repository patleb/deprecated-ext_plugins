namespace :ext_devise do
  desc 'create user'
  task :create_user, [:email, :password] => :environment do |t, args|
    User.create!(email: args[:email], password: args[:password], password_confirmation: args[:password])
  end
end
