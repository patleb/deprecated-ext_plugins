class PagesYml
  class InvalidYaml < ::StandardError
  end

  CATEGORIES = %i(
    layouts
    pages
  ).freeze

  PAGE_OPTIONS = %i(
    type
    multiple
  ).freeze

  CONTENT_OPTIONS = %i(
    type
    multiple
    range
  ).freeze

  MULTIPLE     = '+'.freeze
  WITH_OPTIONS = /_([#{MULTIPLE}]+)$/

  @@page_types = {}
  @@content_types = {}

  def self.load
    return self if @yml

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

  def self.load!
    clear
    load
  end

  def self.clear
    instance_variables.each do |ivar|
      instance_variable_set(ivar, nil)
    end

    self
  end

  def self.pages_layout
    @layout ||= layouts.first.first
  end

  def self.pages_types
    @names ||= pages.keys.each_with_object({}) do |page, memo|
      @pages_with_options ||= {}
      without_options = page.sub WITH_OPTIONS, ''
      @pages_with_options[without_options] = page
      without_options
      memo[without_options] = page_type_class(without_options)
    end
  end

  def self.fetch_contents(page)
    layout = page.layout.view
    raise ArgumentError, "layout [#{layout}] not found" unless layouts.has_key? layout
    categories = { layouts: layout }
    page = page.view
    raise ArgumentError, "page [#{page}] not found" unless pages_types.has_key? page
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
            type: page_type_class(view),
            multiple: options.include?(MULTIPLE),
          }
        end
      contents.merge!(@contents[category][view] ||= begin
        view_contents = send(category)[view_with_options] || {}
        {
          "#{category}/#{view}" => view_contents.each_with_object(view_options) do |(content, types), memo|
            # TODO validate_types(types)
            types.each do |type, range|
              type, range = content_type_class(type), range.to_range
              validate_range(range)
              content, options = split_options(category, content)
              (memo[content] ||= []) << {
                type: type,
                multiple: options.include?(MULTIPLE),
                range: range,
              }
            end
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

  def self.validate_types(types)
    # TODO
  end
  
  def self.validate_range(range)
    raise ArgumentError, "bad range [#{range.begin}] is not <= [#{range.end}]" unless range.begin <= range.end
  end

  # TODO extract as concern
  def self.page_type_class(name)
    klass = "Page::#{name.to_s.camelize}"
    if @@page_types.has_key? klass
      @@page_types[klass]
    else
      @@page_types[klass] = klass.constantize
    end
  rescue NameError, LoadError
    @@page_types[klass] = Page::Simple
  end

  def self.content_type_class(name)
    klass = "Content::#{name.to_s.camelize}"
    if @@content_types.has_key? klass
      @@content_types[klass]
    else
      @@content_types[klass] = klass.constantize
    end
  end
end
