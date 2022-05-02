require_relative 'base'

class ResetCommand < BaseCommand
  def self.run(save: true)
    active_week = Budget.active_week

    unless self.is_diverged?
      puts "Already reset."
      return
    end

    if save
      if Budget.archived.exists?(week: active_week)
        puts "Week #{active_week} has already been pushed to the history. Would you like to overwrite? [y/N]"
        answer = STDIN.gets.chomp
        if yes?(answer)
          Budget.archived.where(week: active_week).delete_all
        else
          return
        end
      end

      Budget.active.update(status: :archived)
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
    budgets = []
    budgets << Budget.make(:unknown, 0.0) if Env.fetch_bool('ENABLE_UNKNOWN', true)
    budgets << Budget.make(:unbudgeted, 0.0) if Env.fetch_bool('ENABLE_UNBUDGETED', true)
    Rails.application.config_for(:budgets)[:initial_budgets].each do |slug, hours|
      budgets << Budget.make(slug, hours)
    end
    budgets
  end
end
