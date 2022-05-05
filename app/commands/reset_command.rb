class ResetCommand < BaseCommand
  def self.run
    if Week.exists?(date: Date.today.beginning_of_week)
      puts "You are about to reset an existing week. Continue? [y/N]"
      return unless yes?(STDIN.gets.chomp)
      "> Resetting #{Week.active}..."
      Week.active.budgets = Budget.defaults
      Week.active.save!
    else
      week = Week.this_week
      puts "> Moving to new week! #{week}"
      week.budgets = Budget.defaults
      week.save!
      Week.activate(week)
    end
  end

  def self.is_diverged?
    current_active = Week.active.budgets.map(&:to_comparable)
    current_active != Budget.defaults.map(&:to_comparable)
  end
end
