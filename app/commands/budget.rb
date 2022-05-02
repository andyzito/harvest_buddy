require_relative '../models/budget'

class BudgetCommand
  def self.create_or_update(budget_slug, time_budgeted)
    if Week.active.budget_exists?(budget_slug)
      budget = Week.active.find_budget(budget_slug)
      old_time_budgeted = budget.time_budgeted
      if time_budgeted.match(/(\+|\-)[\d\.]+/)
        budget.time_budgeted = budget.time_budgeted + time_budgeted.to_f
      else
        budget.time_budgeted = time_budgeted.to_f
      end
      puts "> #{budget.slug}: #{old_time_budgeted} → #{budget.time_budgeted}"
      budget.save!
    else
      budget = Budget.make(budget_slug, time_budgeted, week: Week.active)
      budget.save!
      puts "> #{budget.slug}: #{budget.time_budgeted}"
    end
  end

  def self.remove(budget_slug)
    if Week.active.budget_exists?(budget_slug)
      budget = Week.active.find_budget(budget_slug)
      puts "> Deleting #{budget.slug} (#{budget.time_spent}/#{budget.time_budgeted})"
      Week.active.delete_budget(budget_slug)
    else
      puts "Budget #{budget_slug} does not exist in the active week."
    end
  end

  def self.move(from_slug:, hours:, to_slug:)
    from_budget = Week.active.find_budget(slug: from_slug)
    to_budget = Week.active.find_budget(slug: to_slug)

    raise "#{from_slug} doesn't exist" unless from_budget

    if hours === false
      puts "No hours provided -- assume hours left in #{from_budget.slug} (#{from_budget.time_left})? [y/N]"
      answer = STDIN.gets.chomp
      return unless answer.match(/y(es)?/i)
      hours = from_budget.time_left
    elsif hours > from_budget.time_budgeted
      puts "#{from_budget.slug} only has #{from_budget.time_budgeted} -- move them all? [y/N]"
      answer = STDIN.gets.chomp
      return unless answer.match(/y(es)?/i)
      hours = from_budget.time_budgeted
    elsif hours > from_budget.time_left
      puts "#{from_budget.slug} will have negative time_left, proceed? [y/N]"
      answer = STDIN.gets.chomp
      return unless answer.match(/y(es)?/i)
    end

    unless to_budget
      if Env.fetch_bool('ENABLE_CREATE_ON_MV', true)
        to_budget = Budget.make(to_slug, 0, week: Week.active)
      else
        raise "#{to_slug} doesn't exist"
      end
    end

    from_hours = from_budget.time_budgeted - hours
    to_hours = to_budget.time_budgeted + hours

    # puts "> #{from_budget.slug}: #{from_budget.time_budgeted} - #{hours} = #{from_hours}"
    # puts "> #{to_budget.slug}: #{to_budget.time_budgeted} + #{hours} = #{to_hours}"

    puts "> #{from_budget.slug}: #{from_budget.time_budgeted} ➾ #{from_hours}"
    puts "> #{to_budget.slug}: #{to_budget.time_budgeted} ➾ #{to_hours}"

    to_budget.update!(time_budgeted: to_hours)
    from_budget.update!(time_budgeted: from_hours)
  end
end
