class Budget < ActiveRecord::Base

  enum status: [:active, :archived]

  def self.make(slug, time_budgeted, time_spent = 0, status: :active)
    instance = self.new
    instance.slug = slug
    instance.time_budgeted = time_budgeted
    instance.time_spent = time_spent
    instance.status = status
    instance.week = self.active_week
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

  def self.total_budgeted(week = self.active_week, status: :active)
    Budget.where(week: week, status: status).sum(&:time_budgeted).round
  end

  def self.total_spent(week = self.active_week, status: :active)
    Budget.where(week: week, status: status).sum(&:time_spent).round
  end

  def self.total_left(week = self.active_week, status: :active)
    Budget.where(week: week, status: status).sum(&:time_left).round
  end

  def self.weeks
    Budget.order(week: :desc).distinct.pluck(:week).compact
  end

  def self.active_week
    Budget.active.sample&.week || Date.today.beginning_of_week
  end

  def to_comparable
    {
      slug: slug,
      time_spent: time_spent.to_f,
      time_budgeted: time_budgeted.to_f,
      time_left: time_left.to_f
    }
  end
end
