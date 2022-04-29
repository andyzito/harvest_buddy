class AddWeekToBudget < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :week, :date
  end
end
