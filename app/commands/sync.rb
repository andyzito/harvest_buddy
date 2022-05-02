class SyncCommand
  def self.run
    week = Week.active

    response = Faraday.get(
      "https://api.harvestapp.com/api/v2/time_entries",
      {
        user_id: ENV.fetch('HARVEST_USER_ID'),
        from: week.beginning_of_week,
        to: week.end_of_week,
      },
      {
        'Harvest-Account-ID': ENV.fetch('HARVEST_ACCOUNT_ID'),
        'Authorization': "Bearer #{ENV.fetch('HARVEST_ACCESS_TOKEN')}",
        "Accept" => "application/json"
      }
    )

    time_entries = JSON.parse(response.body)['time_entries']

    budget_totals = {
      unbudgeted: 0,
      unknown: 0,
    }

    time_entries.each do |time|
      budget_slug = time['notes'][/\[hbb\:([a-z0-9\-\_]+)\]/,1]&.to_sym

      budget_slug = :unbudgeted unless budget_slug
      budget_slug = :unknown unless Week.active.budget_exists?(budget_slug)

      budget_totals[budget_slug] ||= 0
      budget_totals[budget_slug] += time['hours'].to_f
    end

    budget_totals.each do |budget_slug, hours|
      budget = Week.active.find_budget(budget_slug)
      budget.update!(time_spent: hours)
      puts "Synced #{budget_slug}=#{budget.time_spent}/#{budget.time_budgeted}"
    end
  end
end
