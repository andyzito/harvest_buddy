class Budget < ActiveRecord::Base

  belongs_to :week

  validates :slug, presence: true

  SLUG_PATTERN = /[a-zA-Z0-9\-\_]*/
  COMBOSLUG_PATTERN = /([a-zA-Z0-9\-\_]*)\:([a-zA-Z0-9\-\_]*)/

  # def self.make(group_slug, slug, time_budgeted, time_spent = 0, week: nil)
  #   instance = self.new
  #   instance.group = group_slug
  #   instance.slug = slug
  #   instance.time_budgeted = time_budgeted
  #   instance.time_spent = time_spent
  #   instance.week = week
  #   return instance
  # end

  def self.parse_comboslug(comboslug)
    return nil, nil if comboslug.nil? || comboslug.empty?

    group_slug = comboslug[COMBOSLUG_PATTERN, 1]&.to_sym&.presence
    budget_slug = comboslug[COMBOSLUG_PATTERN, 2]&.to_sym&.presence
    return group_slug, budget_slug
  end

  def comboslug
    "#{group}:#{slug}"
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
      group: group,
      slug: slug,
      time_spent: time_spent.to_f,
      time_budgeted: time_budgeted.to_f,
      time_left: time_left.to_f
    }
  end

  def self.defaults
    budgets = []
    budgets << Budget.new(
      group: :meta,
      slug: :unbudgeted,
      time_budgeted: 0.0
    ) if Env.fetch_bool('ENABLE_UNBUDGETED', true)
    defaults_total = 0
    Rails.application.config_for(:budgets)[:initial_budgets].each do |group, _budgets|
      _budgets.each do |slug, hours|
        defaults_total += hours
        budgets << Budget.new(
          group: group,
          slug: slug,
          time_budgeted: hours
        )
      end
    end
    flexible_total = ENV.fetch('FLEXIBLE_TOTAL', 0).to_f
    budgets << Budget.new(
      group: :meta,
      slug: :flex,
      time_budgeted: (flexible_total - defaults_total)
    ) unless flexible_total.zero?
    budgets
  end

  def self.group(group_slug)
    Budget.where(group: group_slug)
  end
end
