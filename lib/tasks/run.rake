require_relative '../../app/commands/budget.rb'
require_relative '../../app/commands/summary.rb'
require_relative '../../app/commands/sync.rb'
require_relative '../../app/commands/reset.rb'
require_relative '../../app/commands/history.rb'
require 'dotenv'

desc "runme"
task hbb: :environment do
  ARGV.each { |a| task a.to_sym do ; end }

  Dotenv.load('.env', '.env.local')

  command = ARGV[1]
  case command
  when 'budget', 'b'
    BudgetCommand.create_or_update(ARGV[2], ARGV[3])
  when 'summary', 's'
    SummaryCommand.run
    exit
  when 'move', 'mv', 'rebudget'
    from_slug = ARGV[2]
    hours = ARGV[3].is_number? ? ARGV[3].to_f : false
    to_slug = ARGV[3].is_number? ? ARGV[4] : ARGV[3]

    BudgetCommand.move(
      from_slug: from_slug,
      hours: hours,
      to_slug: to_slug,)
  when 'sync'
    SyncCommand.run
  when 'reset', 'r'
    ResetCommand.run(
      save: Env.fetch_bool('SAVE', true),
    )
  when 'history', 'h'
    subcommand = ARGV[2]
    case subcommand
    when 'restore', 'r'
      HistoryCommand.restore(ARGV[3])
    when 'summary', 's', nil
      HistoryCommand.summary
      exit
    end
  else
    puts "unknown command"
    exit
  end
  if Env.fetch_bool('ALWAYS_SHOW_SUMMARY_AFTER', false)
    SummaryCommand.run
  end
end
