class PagesYml
  class InvalidYaml < ::StandardError
  end

  CATEGORIES = %i(
    layouts
    pages
  ).freeze

  PAGE_OPTIONS = %i(
    with_copies
    skip_cache
  ).freeze

  CONTENT_OPTIONS = %i(
    with_copies
    range
  ).freeze

  WITH_COPIES   = '+'.freeze
  WITHOUT_CACHE = '!'.freeze
  WITH_OPTIONS  = /_([#{WITH_COPIES}#{WITHOUT_CACHE}]{1,2})$/

  def self.initialize!
    clear

    file = Pathname.new(ExtPages.config.pages_config_path).expand_path
    @yml = YAML.load(ERB.new(file.read).result).with_indifferent_access
    @yml.each do |category, views|
      raise InvalidYaml, "unknown category [#{category}]" unless CATEGORIES.include? category.to_sym

      instance_variable_set :"@#{category}", views

      send :define_singleton_method, category do
        instance_variable_get :"@#{category}"
      end
    end

    self
  end

  def self.names
    @names ||= begin
      names = pages.keys.map do |page|
        @pages_with_options ||= {}
        without_options = page.sub WITH_OPTIONS, ''
        @pages_with_options[without_options] = page
        without_options
      end
      Set.new(names)
    end
  end

  def self.fetch_contents(page)
    layout = page.layout.view
    raise ArgumentError, "layout [#{layout}] not found" unless layouts.has_key? layout
    categories = { layouts: layout }
    page = page.view
    raise ArgumentError, "page [#{page}] not found" unless names.include? page
    categories[:pages] = page

    @contents ||= { layouts: {}, pages: {} }

    categories.each_with_object({}) do |(category, view), contents|
      view_with_options = @pages_with_options[view] || view
      view_options =
        if category == :layouts
          {}
        else
          _view, options = split_options(category, view_with_options)
          { 
            with_copies: options.include?(WITH_COPIES),
            skip_cache: options.include?(WITHOUT_CACHE)
          }
        end
      contents.merge!(@contents[category][view] ||= begin
        view_contents = send(category)[view_with_options] || {}
        {
          "#{category}/#{view}" => view_contents.each_with_object(view_options) do |(content, type), memo|
            # TODO could have multiple types
            type, range = type.first
            type, range = "Content::#{type.camelize}".constantize, range.to_range
            validate_range(range)
            content, options = split_options(category, content)
            (memo[type] ||= {})[content] = {
              with_copies: options.include?(WITH_COPIES),
              range: range,
            }
          end
        }
      end)
    end
  end

  private_class_method

  def self.split_options(category, name)
    if category != :layouts && (result = name.match(WITH_OPTIONS))
      [name.sub(WITH_OPTIONS, ''), result[1]]
    else
      [name, '']
    end
  end

  def self.validate_range(range)
    raise ArgumentError, "bad range [#{range.begin}] is not <= [#{range.end}]" unless range.begin <= range.end
  end

  def self.clear
    instance_variables.each do |ivar|
      instance_variable_set(ivar, nil)
    end
  end
end
