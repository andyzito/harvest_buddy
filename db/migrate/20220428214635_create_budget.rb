class CreateBudget < ActiveRecord::Migration[6.0]
  def change
    create_table :budgets do |t|
      t.string :slug
      t.decimal :time_budgeted
      t.decimal :time_spent
    end
  end
end
