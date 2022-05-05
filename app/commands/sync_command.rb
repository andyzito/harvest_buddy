class SyncCommand
  def self.run
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

    time_entries.each do |time|
      group_slug = time['notes'][/\[hbb\:([a-zA-Z0-9\-\_]*)\:([a-zA-Z0-9\-\_]*)\]/,1]&.to_sym
      budget_slug = time['notes'][/\[hbb\:([a-zA-Z0-9\-\_]*)\:([a-zA-Z0-9\-\_]*)\]/,2]&.to_sym

      if group_slug.nil? || budget_slug.nil? || (budget_slug.empty? && group_slug.empty?) # This time entry does not have a tag.
        if Env.fetch_bool('ENABLE_META_UNBUDGETED', true)
          group_slug = META_GROUP_SLUG
          budget_slug = :unbudgeted
        end
      elsif budget_slug.empty? # [hbb:group:] (no budget slug, but has a group slug)
        budget_slug = :unbudgeted
      end

      # puts time['notes'] if budget_slug == :unbudgeted

      if group_slug.empty?
        default_groups = Rails.application.config_for(:budgets)[:default_groups]
        group_slug = default_groups[budget_slug] if default_groups.key?(budget_slug)
      end

      totals[group_slug.to_sym] ||= {}
      totals[group_slug.to_sym][budget_slug.to_sym] ||= 0
      totals[group_slug.to_sym][budget_slug.to_sym] += time['hours'].to_f
    end

    totals.each do |group_slug, budgets|
      budgets.each do |budget_slug, hours|
        budget = Week.active.find_budget(group_slug, budget_slug, create: true)
        budget.time_spent = hours
        budget.save!
        puts "Synced #{budget.comboslug}=#{budget.time_spent}/#{budget.time_budgeted}"
      end
    end
  end
end
