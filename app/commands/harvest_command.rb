class HarvestCommand < BaseCommand
  def self.sync
    week = Week.active

    response = Faraday.get(
      "https://api.harvestapp.com/api/v2/time_entries",
      {
        user_id: ENV.fetch('HARVEST_USER_ID'),
        from: week.date.beginning_of_week,
        to: week.date.end_of_week,
      },
      {
        'Harvest-Account-ID': ENV.fetch('HARVEST_ACCOUNT_ID'),
        'Authorization': "Bearer #{ENV.fetch('HARVEST_ACCESS_TOKEN')}",
        "Accept" => "application/json"
      }
    )

    time_entries = JSON.parse(response.body)['time_entries']

    totals = {
      meta: {
        unbudgeted: 0,
      }
    }

    default_tags = Rails.application.config_for(:budgets)[:default_tags]
    default_groups = Rails.application.config_for(:budgets)[:default_groups]

    time_entries.each do |time|
      group_slug, budget_slug = extract_comboslug(time['notes'])

      if group_slug.nil? && budget_slug.nil?
        task_name = time['task']['name']
        if default_tags.key?(task_name)
          group_slug, budget_slug = self.extract_comboslug(default_tags[task_name])
        else
          byebug
          group_slug = :meta
          budget_slug = :unbudgeted
        end
      end

      if group_slug.nil? && budget_slug.present?
        if default_groups.key?(budget_slug)
          group_slug = default_groups[budget_slug]
        else
          group_slug = :meta
          budget_slug = :unbudgeted
        end
      elsif group_slug.present? && budget_slug.nil?
        budget_slug = :unbudgeted
      end

      byebug if group_slug.nil?
      # puts time['notes'] if budget_slug == :unbudgeted

      totals[group_slug.to_sym] ||= {}
      totals[group_slug.to_sym][budget_slug.to_sym] ||= 0
      totals[group_slug.to_sym][budget_slug.to_sym] += time['hours'].to_f
    end

    totals.each do |group_slug, budgets|
      budgets.each do |budget_slug, hours|
        budget = Week.active.find_budget("#{group_slug}:#{budget_slug}", create: true)
        budget.time_spent = hours
        budget.save!
        puts "Synced #{budget.comboslug}=#{budget.time_spent}/#{budget.time_budgeted}"
      end
    end
  end

  def self.round
  end

  def self.extract_comboslug(text)
    comboslug = text[/\[hbb\:(#{Budget::COMBOSLUG_PATTERN})\]/, 1]
    # group_slug = text[Budget::COMBOSLUG_PATTERN, 1]&.to_sym.presence
    # budget_slug = text[Budget::COMBOSLUG_PATTERN, 2]&.to_sym.presence
    Budget.parse_comboslug(comboslug)
  end
end
