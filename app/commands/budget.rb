require_relative '../models/budget'
require_relative 'base'

class BudgetCommand < BaseCommand
  def self.create_or_update(budget_slug, hours)
    if Week.active.budget_exists?(budget_slug)
      budget = Week.active.find_budget(budget_slug)
      old_time_budgeted = budget.time_budgeted
      if hours.match(/(\+|\-)[\d\.]+/)
        budget.time_budgeted = budget.time_budgeted + hours.to_f
        flex_diff = -1 * hours.to_f
      else
        budget.time_budgeted = hours.to_f
        flex_diff = old_time_budgeted - hours.to_f
      end
    else
      budget = Budget.make(budget_slug, hours, week: Week.active)
      flex_diff = 0 - hours.to_f
    end

    puts "> #{budget.slug}: #{old_time_budgeted.present? ? "#{old_time_budgeted} → " : ''}#{budget.time_budgeted}"
    self.flex(flex_diff) unless budget_slug == 'flex'
    budget.save!
  end

  def self.flex(diff)
    flex_total = Env.fetch('FLEXIBLE_TOTAL', 0).to_f

    return if flex_total.zero?

    flex = Week.active.find_budget('flex')

    return unless flex.present?

    new_flex_hours = flex.time_budgeted + diff

    if new_flex_hours < 0
      puts "You do not have enough flex hours left to perform this action (#{diff}). Proceed anyway? [y/N]"
      exit unless yes?(STDIN.gets.chomp)
    elsif new_flex_hours > flex_total
      raise "Somehow you've done a thing that attempted to exceed the FLEXIBLE_TOTAL #{flex_total}"
    end

    puts "> #{flex.slug}: #{flex.time_budgeted} → #{new_flex_hours}"
    flex.time_budgeted = new_flex_hours
    flex.save!
  end

  def self.remove(budget_slug)
    if budget_slug == 'flex' && Env.fetch('FLEXIBLE_TOTAL', 0).positive?
      puts "Flex is a magic budget which you may not modify directly."
      puts "It will hold budgeted hours leftover from other budgets, up to FLEXIBLE_TOTAL."
      return
    end

    if Week.active.budget_exists?(budget_slug)
      budget = Week.active.find_budget(budget_slug)
      puts "> Deleting #{budget.slug} (#{budget.time_spent}/#{budget.time_budgeted})"
      Week.active.delete_budget(budget_slug)
    else
      puts "Budget #{budget_slug} does not exist in the active week."
    end
  end

  def self.move(from_slug:, hours:, to_slug:)
    from_budget = Week.active.find_budget(from_slug)
    to_budget = Week.active.find_budget(to_slug)

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
