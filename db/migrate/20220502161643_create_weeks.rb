class CreateWeeks < ActiveRecord::Migration[6.0]
  def change
    create_table :weeks do |t|
      t.date :date
      t.boolean :active
    end

    add_reference :budgets, :week
  end
end
