class Week < ActiveRecord::Base

  has_many :budgets

  validates :date, presence: true

  # scope :active, -> { find_by(active: true) }
  def self.active
    Week.find_by(active: true)
  end

  def self.latest
    Week.order(:date).last
  end

  def self.this_week
    date = Date.today.beginning_of_week
    if Week.exists?(date: date)
      return Week.find_by(date: date)
    else
      return Week.make
    end
  end

  def self.make(date = Date.today.beginning_of_week, active = false)
    instance = self.new
    instance.date = date.beginning_of_week
    instance.active = active
    return instance
  end

  def short_label
    "#{date}"
  end

  def long_label
    "Week of #{short_label}"
  end

  def summary_label
    "#{active ? '*' : ''}#{short_label}"
  end

  def to_s
    "#{long_label}"
  end

  def total_budgeted
    budgets.sum(&:time_budgeted).round
  end

  def total_spent
    budgets.sum(&:time_spent).round
  end

  def total_left
    budgets.sum(&:time_left).round
  end

  def budget_exists?(slug)
    budgets.exists?(slug: slug)
  end

  def find_budget(slug)
    budgets.find_by(slug: slug)
  end

  def delete_budget(slug)
    budgets.delete_by(slug: slug)
  end

  def self.activate(week)
    Week.where(active: true).update_all(active: false)
    week.update!(active: true)
  end
end
