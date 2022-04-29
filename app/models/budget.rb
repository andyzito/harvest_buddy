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

  def self.total_budgeted
    Budget.all.sum(&:time_budgeted).round
  end

  def self.total_spent
    Budget.all.sum(&:time_spent).round
  end

  def self.total_left
    Budget.all.sum(&:time_left).round
  end
end
