require_relative '../../app/commands/budget.rb'
require_relative '../../app/commands/summary.rb'
require_relative '../../app/commands/sync.rb'

desc "runme"
task hbb: :environment do
  ARGV.each { |a| task a.to_sym do ; end }

  command = ARGV[1]
  case command
  when 'budget', 'b'
    BudgetCommand.create_or_update(ARGV[2], ARGV[3])
  when 'summary', 's'
    SummaryCommand.run
  when 'move', 'mv', 'rebudget'
    from_slug = ARGV[2]
    hours = ARGV[3].is_number? ? ARGV[3] : false
    to_slug = ARGV[3].is_number? ? ARGV[4] : ARGV[3]

    BudgetCommand.move(
      from_slug: from_slug,
      hours: hours,
      to_slug: to_slug,)
  else
    puts "unknown command"
  end
end
