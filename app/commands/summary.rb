class SummaryCommand
  def self.run
    table = Terminal::Table.new do |t|
      t.add_row ['', 'Spent', 'Budgeted', 'Left']
      t.add_separator
      t.add_row ['', Budget.total_spent, Budget.total_budgeted, Budget.total_left]
      t.add_separator
      Budget.all.each do |budget|
        # next if budget.time_budgeted == 0
        t.add_row [budget.slug, budget.time_spent, budget.time_budgeted, budget.time_left]
      end
    end
    puts table
  end
end
