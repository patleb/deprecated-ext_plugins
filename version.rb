module ExtPlugins
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    unless defined? RAILS_MAJOR
      RAILS_MAJOR = 5
      RAILS_MINOR = 1
      MAJOR = 0
      MINOR = 1
    end

    STRING = [RAILS_MAJOR, RAILS_MINOR, MAJOR, MINOR].compact.join(".")
  end
end
