ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
require 'dotenv'

Dotenv.load('.env.local')

class String
  def is_number?
    true if Float(self) rescue false
  end
end

class Float
  def round_to_quarter
    (self * 4).round / 4.0
  end
end

class Env
  def self.fetch(key, default)
    ENV.fetch(key, default)
  end

  def self.fetch_bool(key, default)
    if ENV.fetch(key, nil).in?(['true', 1])
      true
    elsif ENV.fetch(key, nil).in?(['false', 0])
      false
    else
      default
    end
  end
end
