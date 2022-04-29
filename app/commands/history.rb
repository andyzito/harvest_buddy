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
        t.add_row [week, Budget.total_spent(week), Budget.total_budgeted(week), Budget.total_left(week)]
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

    to_restore = Budget.where(week: week)
    if to_restore.empty?
      puts 'This week is not stored in the history'
      return
    elsif ResetCommand.is_diverged?
      puts "There is data in your active budgets, are you sure you want to overwrite? [y/N]"
      return unless yes?(STDIN.gets.chomp)
    end

    Budget.active.delete_all
    restored = Budget.where(week: week).map(&:dup)
    restored.map { |r| r.week = nil }
    restored.map(&:save!)
  end
end
