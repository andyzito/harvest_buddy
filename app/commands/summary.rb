class SummaryCommand
  def self.run(budgets=Week.active.budgets)
    table = Terminal::Table.new title: Week.active.long_label do |t|
      t.add_row ['', 'Spent', 'Budgeted', 'Left']
      t.add_separator
      t.add_row ['', Week.active.total_spent, Week.active.total_budgeted, Week.active.total_left]
      t.add_separator
      budgets.order(time_budgeted: :desc).each do |budget|
        next if budget.time_left == 0 && Env.fetch_bool('HIDE_DONE', false)
        t.add_row [budget.slug, budget.time_spent, budget.time_budgeted, budget.time_left]
      end
    end
    puts table
  end
end
