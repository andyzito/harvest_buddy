require_relative '../models/budget'

class BudgetCommand
  def self.create_or_update(budget_slug, time_budgeted)
    if Budget.exists?(slug: budget_slug)
      budget = Budget.all_active.find_by(slug: budget_slug)
      if time_budgeted.match(/(\+|\-)[\d\.]+/)
        new_time_budgeted = budget.time_budgeted + time_budgeted.to_f
      else
        new_time_budgeted = time_budgeted.to_f
      end
      puts "> #{budget.slug}: #{budget.time_budgeted} → #{new_time_budgeted}"
      budget.update!(time_budgeted: new_time_budgeted)
    else
      budget = Budget.make(budget_slug, time_budgeted)
      budget.save!
      puts "> #{budget.slug}: #{budget.time_budgeted}"
    end
  end

  def self.move(from_slug:, hours:, to_slug:)
    from_budget = Budget.all_active.find_by(slug: from_slug)
    to_budget = Budget.all_active.find_by(slug: to_slug)

    raise "#{from_budget} doesn't exist" unless from_budget
    raise "#{to_budget} doesn't exist" unless to_budget

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
