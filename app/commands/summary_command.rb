class SummaryCommand
  def self.run
    # project_budgets = budgets.reject { |b| b.slug.in? ['flex', 'maint', 'break', 'meetings'] }
    # default_budgets = budgets - project_budgets
    table = Terminal::Table.new title: Week.active.long_label do |t|
      t.add_row ['', 'Spent', 'Budgeted', 'Left']
      t.add_separator
      t.add_row ['TOTAL', Week.active.total_spent, Week.active.total_budgeted, Week.active.total_left]
      Week.active_groups.each do |group|
        group_done = Week.active.total_left(group) == 0
        t.add_separator
        row = [group.to_s.bold, Week.active.total_spent(group).to_s.bold, Week.active.total_budgeted(group).to_s.bold, Week.active.total_left(group).to_s.bold]
        row = row.map do |x|
          x = x.to_s.bold
          x = x.light_black if group_done
          x
        end
        t.add_row row
        budgets = Week.active.group(group)
        budgets = (budgets.sort_by { |b| b.time_left }).reverse
        budgets.each do |budget|
          done = budget.time_left == 0
          row = [" #{budget.slug}", budget.time_spent, budget.time_budgeted, budget.time_left]
          row = row.map { |x| x.to_s.light_black } if done
          t.add_row row
        end
    end
    end
    puts table
  end
end
