class Budget < ActiveRecord::Base

  belongs_to :week

  def self.make(slug, time_budgeted, time_spent = 0, week: nil)
    instance = self.new
    instance.slug = slug
    instance.time_budgeted = time_budgeted
    instance.time_spent = time_spent
    instance.week = week
    return instance
  end

  def hours_format(number)
    v = number.to_f.round_to_quarter
    v % 1 == 0 ? v.to_int : v
  end

  def time_left
    hours_format(time_budgeted - (time_spent || 0))
  end

  def time_spent
    db_value = super
    hours_format(db_value)
  end

  def time_budgeted
    db_value = super
    hours_format(db_value)
  end

  def time_spent=(value)
    super(value.to_f.round_to_quarter)
  end

  def time_budgeted=(value)
    super(value.to_f.round_to_quarter)
  end

  def to_comparable
    {
      slug: slug,
      time_spent: time_spent.to_f,
      time_budgeted: time_budgeted.to_f,
      time_left: time_left.to_f
    }
  end

  def self.defaults
    budgets = []
    budgets << Budget.make(:unknown, 0.0) if Env.fetch_bool('ENABLE_UNKNOWN', true)
    budgets << Budget.make(:unbudgeted, 0.0) if Env.fetch_bool('ENABLE_UNBUDGETED', true)
    defaults_total = 0
    Rails.application.config_for(:budgets)[:initial_budgets].each do |slug, hours|
      defaults_total += hours
      budgets << Budget.make(slug, hours)
    end
    flexible_total = ENV.fetch('FLEXIBLE_TOTAL', 0).to_f
    budgets << Budget.make(:flex, (flexible_total - defaults_total)) unless flexible_total.zero?
    budgets
  end
end
