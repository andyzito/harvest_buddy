require_relative 'base'

class ResetCommand < BaseCommand
  def self.run(save: true)
    active_week = Budget.active_week

    if !self.is_diverged? && active_week.in?(Budget.weeks)
      puts "Already reset."
      return
    end

    if active_week.in?(Budget.weeks)
      puts "You are about to reset an existing week. Continue? [y/N]"
      return unless yes?(STDIN.gets.chomp)
    else
      Budget.active.update_all(status: :archived)
    end

    Budget.active.delete_all
    "> Resetting #{active_week}..."
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
