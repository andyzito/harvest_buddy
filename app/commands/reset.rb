class ResetCommand
  def self.run
    Budget.delete_all

    meetings = Float(ENV.fetch('INITIAL_BUDGET_FOR_MEETINGS', 8))
    flex = Float(ENV.fetch('INITIAL_BUDGET_FOR_FLEX', 5))

    Budget.make(:unknown, 0).save! if Env.fetch_bool('ENABLE_UNKNOWN', true)
    Budget.make(:unbudgeted, 0).save! if Env.fetch_bool('ENABLE_UNBUDGETED', true)
    Budget.make(:meetings, meetings).save! if meetings.positive?
    Budget.make(:flex, flex).save! if flex.positive?
  end
end
