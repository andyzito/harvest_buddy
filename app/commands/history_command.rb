class HistoryCommand < BaseCommand
  def self.summary
    table = Terminal::Table.new do |t|
      t.add_row ['Week', 'Total Spent', 'Total Budgeted', 'Total Left']
      t.add_separator
      Week.all.each do |week|
        t.add_row [
          week.summary_label,
          week.total_spent,
          week.total_budgeted,
          week.total_left,
        ]
      end
    end
    puts table
  end

  def self.travel(week = nil)
    if week.nil?
      week = Week.latest
    elsif (minus = week[/^\-(\d+)$/,1])
      week = Week.find_by(date: Date.today.beginning_of_week - minus.to_i.weeks)
    else
      week = week.to_date.beginning_of_week
    end

    if week.nil?
      puts "#{week.long_label} is not stored in the history"
      return
    end

    puts "> Traveling to #{week.long_label}"
    Week.activate(week)
  end
end
