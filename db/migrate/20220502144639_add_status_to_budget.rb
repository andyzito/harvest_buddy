class AddStatusToBudget < ActiveRecord::Migration[6.0]
  def up
    add_column :budgets, :status, :integer, default: 0 unless column_exists? :budgets, :status
    Budget.where(week: nil).update_all(status: :active)
    Budget.where.not(week: nil).update_all(status: :archived)
  end

  def down
    if column_exists? :budgets, :status
      Budget.where(status: :active).update_all(week: nil)
      remove_column :budgets, :status
    end
  end
end
