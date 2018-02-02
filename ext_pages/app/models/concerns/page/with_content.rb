module Page::WithContent
  extend ActiveSupport::Concern

  class_methods do
    def associations
      [:translations]
    end
  end

  def fetch_contents
    existing_contents = Content.where(page: [self, template, layout])
      .order(:page_id, :name, :position)
      .eager_load(:page, *self.class.associations)
    existing_contents = existing_contents.each_with_object({}) do |content, memo|
      view_path = (memo[content.view_path] ||= {})
      (view_path[content.name] ||= []) << content
    end

    result = {}

    synchronize_contents(existing_contents) do |name, records, types|
      result[name.to_sym] = { list: records, types: types }
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
      page_type, page_multiple = contents.slice(*PagesYml::PAGE_OPTIONS).values
      contents.except(*PagesYml::PAGE_OPTIONS).each do |name, types|
        page_contents = (existing_contents[view_path] ||= {})
        records = (page_contents[name] ||= [])
        types.each do |options|
          content_type, content_multiple, type_range = options.slice(*PagesYml::CONTENT_OPTIONS).values
          type_records = records.map{ |record| record.is_a? content_type }
          if type_records.size > type_range.end
            deleted_ids = type_records[type_range.end..-1].map(&:id)
            records.delete_if{ |record| deleted_ids.include? record.id }.each(&:destroy!)
          elsif type_records.size < type_range.begin
            (type_range.begin - type_records.size).times.each do |_i|
              page =
                if view_path.start_with?('layouts/')
                  layout
                elsif content_multiple
                  self
                else
                  template
                end
              records << content_type.create!(page: page, name: name)
            end
          end
        end
      end
    end
  end

  def synchronize_types(existing_contents)
    existing_contents.each do |view_path, contents|
      removed_names = []
      contents.each do |name, records|
        if (page_contents = expected_contents[view_path])
          if (types = page_contents[name])
            types_classes = types.map{ |options| options[:type] }
            records.delete_if{ |record| types_classes.none?{ |type| record.is_a? type } }.each(&:destroy!)
            yield name, records, types
            next
          end
          removed_names << name
        end
        records.each(&:destroy!)
      end
      removed_names.each{ |name| contents.delete(name) }
    end
  end

  def expected_contents
    @_expected_contents ||= PagesYml.fetch_contents(self)
  end
end