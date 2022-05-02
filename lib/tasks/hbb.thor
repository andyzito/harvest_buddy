DIR = File.dirname(__FILE__)
require DIR + '/../../config/environment'

require_relative '../../app/commands/budget.rb'
require_relative '../../app/commands/summary.rb'
require_relative '../../app/commands/sync.rb'
require_relative '../../app/commands/reset.rb'
require_relative '../../app/commands/history.rb'
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

  desc "restore", "restore!"
  map 'r' => :restore
  def restore(week = nil)
    HistoryCommand.restore(week)
  end
end

class Hbb < Thor
  desc "history", ""
  subcommand "history", History
  map 'h' => :history

  desc "summary", ""
  map 's' => :summary
  def summary
    SummaryCommand.run
  end

  desc "sync", ""
  def sync
    SyncCommand.run
  end

  desc "reset", ""
  map 'r' => :reset
  method_option :hard, type: :boolean, default: false
  def reset
    ResetCommand.run(
      save: !options.hard?,
    )
  end

  desc "budget", ""
  map 'b' => :budget
  def budget(slug, hours = 0)
    BudgetCommand.create_or_update(slug, hours)
  end

  desc "remove", ""
  map 'rm' => :remove
  map 'del' => :remove
  map 'delete' => :remove
  def remove(slug, hours = 0)
    BudgetCommand.remove(slug)
  end

  desc "move", ""
  map 'mv' => :move
  map 'rebudget' => :move
  def move(from_slug, hours_or_to_slug, to_slug = '')
    hours = hours_or_to_slug.is_number? ? hours_or_to_slug.to_f : false
    to_slug = hours_or_to_slug.is_number? ? to_slug : hours_or_to_slug

    BudgetCommand.move(
      from_slug: from_slug,
      hours: hours,
      to_slug: to_slug,)
  end

  def self.exit_on_failure?
    true
  end
end
