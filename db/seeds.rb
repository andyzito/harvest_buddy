# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

meetings = ENV.fetch('INITIAL_BUDGET_FOR_MEETINGS', 8)
flex = ENV.fetch('INITIAL_BUDGET_FOR_FLEX', 5)

Budget.make(:unknown, 0).save!
Budget.make(:unbudgeted, 0).save!
Budget.make(:meetings, meetings).save!
Budget.make(:flex, flex).save!
