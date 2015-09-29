# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

u = User.create! email: 'admin@shaolinstpete.com', password: ENV['ADMIN_PASSWORD'], password_confirmation: ENV['ADMIN_PASSWORD'], admin: true, first_name: 'Master', last_name: 'Admin'
u.activate!
