module SunCap
  @sun = SunCap.config

  Dir[SunCap.root.join('lib/sun_cap/commands/**/*.rb').to_s].each do |file|
    name = file.match(/lib\/sun_cap\/commands\/([\w\/]+)\.rb/)[1]
    extend "::SunCap::#{name.camelize}".constantize
  end
end
