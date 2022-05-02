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
          Budget.total_spent(week),
          Budget.total_budgeted(week),
          Budget.total_left(week),
        ]
      end
    end
    puts table
  end

  def self.travel(week = nil)
    if week.nil?
      week = Budget.weeks.last
    elsif (minus = week[/^\-(\d+)$/,1])
      week = Date.today.beginning_of_week - minus.weeks
    else
      week = week.to_date.beginning_of_week
    end

    unless Budget.exists?(week: week)
      puts "Week #{week} is not stored in the history"
      return
    end

    puts "> Traveling to week of #{week}"
    Budget.active.update_all(status: :archived)
    Budget.where(week: week).update_all(status: :active)
  end
end
