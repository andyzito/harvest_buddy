require_relative 'base'

class ResetCommand < BaseCommand
  def self.run(save: true)
    week = Date.today.beginning_of_week

    unless self.is_diverged?
      puts "Already reset."
      return
    end

    if save
      if Budget.exists?(week: week)
        puts "Week #{week} has already been pushed to the history. Would you like to overwrite? [y/N]"
        answer = STDIN.gets.chomp
        if yes?(answer)
          Budget.where(week: week).delete_all
        else
          return
        end
      end

      Budget.active.update(week: week)
    else
      puts "Reset without saving active budgets? [y/N]"
      if yes?(STDIN.gets.chomp)
        Budget.active.delete_all
      else
        return
      end
    end

    self.default_budgets.map(&:save!)
  end

  def self.is_diverged?
    current_active = Budget.active.map(&:to_comparable)
    current_active != default_budgets.map(&:to_comparable)
  end

  def self.default_budgets
    meetings = Float(ENV.fetch('INITIAL_BUDGET_FOR_MEETINGS', 8))
    flex = Float(ENV.fetch('INITIAL_BUDGET_FOR_FLEX', 5))

    budgets = []
    budgets << Budget.make(:unknown, 0.0) if Env.fetch_bool('ENABLE_UNKNOWN', true)
    budgets << Budget.make(:unbudgeted, 0.0) if Env.fetch_bool('ENABLE_UNBUDGETED', true)
    budgets << Budget.make(:meetings, meetings) if meetings.positive?
    budgets << Budget.make(:flex, flex) if flex.positive?
    budgets
  end
end
