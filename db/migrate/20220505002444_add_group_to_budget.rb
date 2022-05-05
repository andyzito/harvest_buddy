class AddGroupToBudget < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :group, :string
  end
end
