require_relative 'base'
require_relative 'summary'
require_relative 'reset'

class HistoryCommand < BaseCommand
  def self.summary
    table = Terminal::Table.new do |t|
      t.add_row ['Week', 'Total Spent', 'Total Budgeted', 'Total Left']
      t.add_separator
      weeks = Budget.weeks
      weeks.each do |week|
        is_active = Budget.active_week == week
        week_label = "#{is_active ? '*' : ''}#{week}"
        t.add_row [
          week_label,
          Budget.total_spent(week, status: :archived),
          Budget.total_budgeted(week, status: :archived),
          Budget.total_left(week, status: :archived),
        ]
      end
    end
    puts table
  end

  def self.restore(week = nil)
    if week.nil?
      week = Budget.weeks.last
    elsif (minus = week[/^\-(\d+)$/,1])
      week = Date.today.beginning_of_week - minus.weeks
    else
      week = week.to_date.beginning_of_week
    end

    to_restore = Budget.archived.where(week: week)
    if to_restore.empty?
      puts "Week #{week} is not stored in the history"
      return
    elsif ResetCommand.is_diverged?
      puts "There is data in your active budgets, are you sure you want to overwrite with week #{week}? [y/N]"
      return unless yes?(STDIN.gets.chomp)
    end

    puts "> Restoring week #{week}"
    Budget.active.delete_all
    restored = Budget.archived.where(week: week).map(&:dup)
    restored.map do |budget|
      budget.week = Budget.active_week # Expected to default to Date.today.beginning_of_week.
      budget.status = :active
      budget.save!
    end
  end
end
