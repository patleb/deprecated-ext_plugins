module Page::WithContent
  extend ActiveSupport::Concern

  def self.associations
    [:translations]
  end

  def fetch_contents
    existing_contents = Content.where(page: [self, template, layout])
      .order(:page_id, :name, :position)
      .eager_load(:page, *Page::WithContent.associations)
    existing_contents = existing_contents.each_with_object({}) do |content, memo|
      view_path = (memo[content.view_path] ||= {})
      type = (view_path[content.class] ||= {})
      (type[content.name] ||= []) << content
    end

    result = { page: to_content }

    synchronize_contents(existing_contents) do |name, type, records, options|
      result[name.to_sym] = { type: type, list: records, **options }
    end

    result
  end

  private

  def synchronize_contents(existing_contents, &block)
    ActiveRecord::Base.transaction do
      synchronize_ranges(existing_contents)
      synchronize_types(existing_contents, &block)
    end
  end

  def synchronize_ranges(existing_contents)
    expected_contents.each do |view_path, contents|
      page_copies, _no_cache = contents.slice(*PagesYml::PAGE_OPTIONS).values
      contents.except(*PagesYml::PAGE_OPTIONS).each do |type, names|
        names.each do |name, options|
          pointer = (existing_contents[view_path] ||= {})
          pointer = (pointer[type] ||= {})
          records = (pointer[name] ||= [])
          content_copies, range = options.slice(*PagesYml::CONTENT_OPTIONS).values
          content_copies &&= page_copies
          if records.size > range.end
            records[range.end..-1].each(&:destroy!)
            records.pop(records.size - range.end)
          elsif records.size < range.begin
            (range.begin - records.size).times.each do |_i|
              page =
                if view_path.start_with?('layouts/')
                  layout
                elsif content_copies
                  is_a?(Page::TemplateCopy) ? self : template
                else
                  is_a?(Page::TemplateCopy) ? template : self
                end
              records << type.create!(page: page, name: name)
            end
          end
        end
      end
    end
  end

  def synchronize_types(existing_contents)
    existing_contents.each do |view_path, contents|
      removed_types = []
      contents.each do |type, names|
        removed_names = []
        names.each do |name, records|
          if (pointer = expected_contents[view_path])
            if (pointer = pointer[type])
              if (options = pointer[name])
                yield name, type, records, options
                next
              end
            end
          end
          records.each(&:destroy!)
          removed_names << name
        end
        removed_names.each{ |name| names.delete(name) }
        removed_types << type if names.empty?
      end
      removed_types.each{ |type| contents.delete(type) }
    end
  end

  def to_content
    @content ||= begin
      # TODO page should not be a content
      options = expected_contents[view_path].slice(*PagesYml::PAGE_OPTIONS)
      options.merge!(
        type: self.class,
        list: [self],
        range: options[:with_copies] ? 1..Float::INFINITY : 1..1
      )
    end
  end

  def expected_contents
    @_expected_contents ||= PagesYml.fetch_contents(self)
  end
end