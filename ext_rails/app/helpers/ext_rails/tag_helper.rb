module ExtRails
  module TagHelper
    HTML_UNSCOPED_TAGS = %i(
      a
      button
      dd
      div
      dl
      dt
      fieldset
      h1
      h2
      h3
      h4
      h5
      h6
      hr
      i
      input
      legend
      li
      pre
      span
      table
      tbody
      td
      th
      thead
      tr
      ul
    ).freeze

    HTML_SCOPED_TAGS = %i(
      label
      p
    ).freeze

    ID_CLASSES = /^[\.#][^\.#]/

    HTML_UNSCOPED_TAGS.each do |tag|
      define_method tag do |*args, &block|
        with_tag tag, *args, &block
      end
    end

    HTML_SCOPED_TAGS.each do |tag|
      define_method "#{tag}_" do |*args, &block|
        with_tag tag, *args, &block
      end
    end

    ExtRails.config.html_extra_tags.each do |tag, scoped|
      define_method "#{tag}#{'_' if scoped}" do |*args, &block|
        with_tag tag, *args, &block
      end
    end

    def self.tags
      @tags ||= HTML_UNSCOPED_TAGS + HTML_SCOPED_TAGS.map{ |tag| :"#{tag}_" } +
        ExtRails.config.html_extra_tags.each_with_object([]) do |(tag, scoped), tags|
          tags << :"#{tag}#{'_' if scoped}"
        end
    end

    def html(*values)
      capture do
        values.flatten.each{ |value| concat value }
      end
    end

    private

    def with_tag(tag, id_classes_or_text = nil, text_or_escape = nil, escape = true, **options, &block)
      case id_classes_or_text
      when ID_CLASSES
        id, classes = parse_id_classes(id_classes_or_text)
        options[:id] ||= id
        options = merge_classes(options, classes)
        text = text_or_escape
      when String, Symbol, Array
        text, escape = id_classes_or_text, text_or_escape
      else
        text = text_or_escape
      end

      if text.nil? && block_given?
        text = block.call
      end

      if text.is_a?(Array)
        text = html(text)
      end

      content_tag tag, text || '', options, escape
    end

    def parse_id_classes(string)
      classes, _separator, id_classes = string.partition('#')
      classes = classes.split('.')
      if id_classes
        id, *other_classes = id_classes.split('.')
        classes.concat(other_classes)
      end
      [id, classes]
    end

    def merge_classes(options, classes)
      if options.key? :class
        options.merge(class: classes) do |_key, old_val, new_val|
          old_array = classes_to_array(old_val)
          new_array = classes_to_array(new_val)
          (old_array | new_array).reject(&:blank?)
        end
      else
        options[:class] = classes_to_array(classes).reject(&:blank?)
        options
      end
    end

    def classes_to_array(classes)
      (classes.is_a?(Array) ? classes : classes.try(:split) || [])
    end
  end
end
