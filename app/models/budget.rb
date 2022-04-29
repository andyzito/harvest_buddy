class Budget < ActiveRecord::Base
  def self.make(slug, time_budgeted, time_spent = 0)
    instance = self.new
    instance.slug = slug
    instance.time_budgeted = time_budgeted
    instance.time_spent = time_spent
    return instance
  end

  def time_left
    time_budgeted - (time_spent || 0)
  end

  def self.all_active
    Budget.where(week: nil)
  end

  def self.total_budgeted(week = nil)
    Budget.where(week: week).sum(&:time_budgeted).round
  end

  def self.total_spent(week = nil)
    Budget.where(week: week).sum(&:time_spent).round
  end

  def self.total_left(week = nil)
    Budget.where(week: week).sum(&:time_left).round
  end

  def self.weeks
    Budget.order(week: :desc).distinct.pluck(:week).compact
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
