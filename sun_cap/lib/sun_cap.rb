require 'require_all'
require 'settings_yml'
require 'ext_shell'
require 'sun_cap/configuration'

module SunCap
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end

require_all SunCap.root.join('lib/sun_cap/commands')
require 'sun_cap/commands'
