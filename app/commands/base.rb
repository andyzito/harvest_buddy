class BaseCommand
  def self.yes?(string)
    string.match(/y(es)?/i)
  end
end
