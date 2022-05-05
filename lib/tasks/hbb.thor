DIR = File.dirname(__FILE__)
require DIR + '/../../config/environment'

require 'dotenv'
require 'thor'

class SubCommandBase < Thor
  def self.banner(command, namespace = nil, subcommand = false)
    "#{basename} #{subcommand_prefix} #{command.usage}"
  end

  def self.subcommand_prefix
    self.name.gsub(%r{.*::}, '').gsub(%r{^[A-Z]}) { |match| match[0].downcase }.gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
  end
end

class History < SubCommandBase
  desc "summary", "summary!"
  map 's' => :summary
  def summary
    HistoryCommand.summary
  end

  desc "travel", "Set active week back in time!"
  map 't' => :travel
  def travel(week = nil)
    HistoryCommand.travel(week)
  end
end

class Hbb < Thor
  desc "history", ""
  subcommand "history", History
  map 'h' => :history

  desc "summary", "Summarize active budgets"
  map 's' => :summary
  def summary
    SummaryCommand.run
  end

  desc "sync", "Sync data from Harvest for active week"
  def sync
    SyncCommand.run
  end

  desc "reset", "Reset to default budgets"
  map 'r' => :reset
  # method_option :hard, type: :boolean, default: false
  def reset
    ResetCommand.run
  end

  desc "budget", "Create/update a budget"
  map 'b' => :budget
  def budget(comboslug, hours = 0)
    group_slug, budget_slug = BudgetCommand.parse_comboslug(comboslug)
    BudgetCommand.create_or_update(group_slug, budget_slug, hours)
  end

  desc "remove", "Remove a budget"
  map 'rm' => :remove
  map 'del' => :remove
  map 'delete' => :remove
  def remove(comboslug, hours = 0)
    group_slug, budget_slug = BudgetCommand.parse_comboslug(comboslug)
    BudgetCommand.remove(group_slug, budget_slug)
  end

  desc "move", "Move hours from one budget to another"
  map 'mv' => :move
  map 'rebudget' => :move
  def move(from_comboslug, hours_or_to_slug, to_comboslug = '')
    hours = hours_or_to_slug.is_number? ? hours_or_to_slug.to_f : false
    to_comboslug = hours_or_to_slug.is_number? ? to_comboslug : hours_or_to_slug

    from_group, from_budget = BudgetCommand.parse_comboslug(from_comboslug)
    to_group, to_budget = BudgetCommand.parse_comboslug(to_comboslug)

    BudgetCommand.move(
      from_group: from_group,
      from_budget_slug: from_budget,
      hours: hours,
      to_group: to_group,
      to_budget_slug: to_budget,
    )
  end

  def self.exit_on_failure?
    true
  end
end
