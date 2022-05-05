class BaseCommand
  def self.yes?(string)
    string.match(/y(es)?/i)
  end

  def self.parse_comboslug(comboslug)
    slugpat = /[a-zA-Z0-9\-\_]*/
    group_slug = comboslug[/(#{slugpat})\:#{slugpat}/,1]
    budget_slug = comboslug[/#{slugpat}\:(#{slugpat})/,1]
    return group_slug&.to_sym, budget_slug&.to_sym
  end
end
