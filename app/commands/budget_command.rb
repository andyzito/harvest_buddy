class BudgetCommand < BaseCommand
  def self.create_or_update(budget, hours)
    old_time_budgeted = budget.time_budgeted
    if hours.match(/(\+|\-)[\d\.]+/)
      budget.time_budgeted = budget.time_budgeted + hours.to_f
      flex_diff = -1 * hours.to_f
    else
      budget.time_budgeted = hours.to_f
      flex_diff = -1 * (hours.to_f - old_time_budgeted)
    end

    puts "> #{budget.comboslug}: #{old_time_budgeted.present? ? "#{old_time_budgeted} → " : ''}#{budget.time_budgeted}"
    self.flex(flex_diff) unless budget.comboslug == 'meta:flex'
    budget.save!
  end

  def self.flex(diff)
    flex_total = Env.fetch('FLEXIBLE_TOTAL', 0).to_f

    return if flex_total.zero?

    flex = Week.active.find_budget('meta:flex')

    return unless flex.present?

    new_flex_hours = flex.time_budgeted + diff

    if new_flex_hours < 0
      puts "You do not have enough flex hours left to perform this action (#{diff}). Proceed anyway? [y/N]"
      exit unless yes?(STDIN.gets.chomp)
    elsif new_flex_hours > flex_total
      raise "Somehow you've done a thing that attempted to exceed the FLEXIBLE_TOTAL #{flex_total}"
    end

    puts "> #{flex.comboslug}: #{flex.time_budgeted} → #{new_flex_hours}"
    flex.time_budgeted = new_flex_hours
    flex.save!
  end

  def self.remove(group_slug, budget_slug)
    if group_slug == :meta && budget_slug == :flex && Env.fetch('FLEXIBLE_TOTAL', 0).positive?
      puts "Flex is a magic budget which you may not modify directly."
      puts "It will hold budgeted hours leftover from other budgets, up to FLEXIBLE_TOTAL."
      return
    end

    if Week.active.budget_exists?(group_slug, budget_slug)
      budget = Week.active.find_budget("#{group_slug}:#{budget_slug}")
      puts "> Deleting #{budget.comboslug} (#{budget.time_spent}/#{budget.time_budgeted})"
      Week.active.delete_budget(group_slug, budget_slug)
    else
      puts "#{group_slug}:#{budget_slug} does not exist in the active week."
    end
  end

  def self.move(from_group:, from_budget_slug:, hours:, to_group:, to_budget_slug:)
    from_budget = Week.active.find_budget("#{from_group}:#{from_budget_slug}")
    to_budget = Week.active.find_budget("#{to_group}:#{to_budget_slug}")

    raise "#{from_group}:#{from_slug} doesn't exist" unless from_budget

    if hours === false
      puts "No hours provided -- assume hours left in #{from_budget.comboslug} (#{from_budget.time_left})? [y/N]"
      return unless yes?(STDIN.gets.chomp)
      hours = from_budget.time_left
    elsif hours > from_budget.time_budgeted
      puts "#{from_budget.comboslug} only has #{from_budget.time_budgeted} budgeted -- move them all? [y/N]"
      return unless yes?(STDIN.gets.chomp)
      hours = from_budget.time_budgeted
    elsif hours > from_budget.time_left
      puts "#{from_budget.comboslug} will have negative time_left, proceed? [y/N]"
      return unless yes?(STDIN.gets.chomp)
    end

    unless to_budget
      if Env.fetch_bool('ENABLE_CREATE_ON_MV', true)
        to_budget = Budget.new(
          group: to_group,
          slug: to_budget_slug,
          time_budgeted: 0,
          week: Week.active
        )
      else
        raise "#{to_group}:#{to_budget_slug} doesn't exist"
      end
    end

    from_hours = from_budget.time_budgeted - hours
    to_hours = to_budget.time_budgeted + hours

    puts "> #{from_budget.comboslug}: #{from_budget.time_budgeted} ➾ #{from_hours}"
    puts "> #{to_budget.comboslug}: #{to_budget.time_budgeted} ➾ #{to_hours}"

    to_budget.update!(time_budgeted: to_hours)
    from_budget.update!(time_budgeted: from_hours)
  end
end
