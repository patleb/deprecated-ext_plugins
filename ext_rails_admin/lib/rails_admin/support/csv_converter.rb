# encoding: UTF-8
require 'csv'

module RailsAdmin
  class CSVConverter
    attr_accessor :controller

    # TODO check to limit like in chart_extractor
    def initialize(controller, abstract_model, objects, schema)
      @fields = []
      @associations = []

      return self if (@objects = objects).nil?

      self.controller = controller
      @abstract_model = abstract_model
      @methods = [(schema[:only] || []) + (schema[:methods] || [])].flatten.compact
      model_config = @abstract_model.config
      @fields = @methods.collect { |m| export_fields_for(m, model_config).first }
      @empty = ::I18n.t('admin.export.empty_value_for_associated_objects')
      schema_include = schema.delete(:include) || {}

      @associations = schema_include.each_with_object({}) do |(name, values), hash|
        association = association_for(name, model_config)
        association_methods = [(values[:only] || []) + (values[:methods] || [])].flatten.compact
        association_model_config = association.associated_model_config

        hash[name] = {
          association: association,
          fields: association_methods.collect { |m| export_fields_for(m, association_model_config).first },
        }
      end
    end

    # https://medium.com/table-xi/stream-csv-files-in-rails-because-you-can-46c212159ab7
    def to_csv(options = {})
      if (estimate = @objects.count_estimate) > RailsAdmin.config.export_max_rows
        raise RailsAdmin::TooManyRows.new("Too many rows: #{estimate} (max: #{RailsAdmin.config.export_max_rows})")
      end

      options = HashWithIndifferentAccess.new(options)
      encoding_to = Encoding.find(options[:encoding_to]) if options[:encoding_to].present?

      csv_string = generate_csv_string(options)
      if encoding_to
        csv_string = csv_string.encode(encoding_to, invalid: :replace, undef: :replace, replace: '?')
      end

      # Add a BOM for utf8 encodings, helps with utf8 auto-detect for some versions of Excel.
      # Don't add if utf8 but user don't want to touch input encoding:
      # If user chooses utf8, they will open it in utf8 and BOM will disappear at reading.
      # But that way "English" users who don't bother and chooses to let utf8 by default won't get BOM added
      # and will not see it if Excel opens the file with a different encoding.
      csv_string = "\xEF\xBB\xBF#{csv_string}" if encoding_to == Encoding::UTF_8

      [!options[:skip_header], (encoding_to || csv_string.encoding).to_s, csv_string]
    end

  private

    def association_for(name, model_config)
      export_fields_for(name, model_config).detect(&:association?)
    end

    def export_fields_for(method, model_config)
      model_config.export.fields.select { |f| f.name == method }
    end

    def generate_csv_string(options)
      generator_options = (options[:generator] || {}).symbolize_keys.delete_if { |_, value| value.blank? }
      # TODO https://github.com/Paxa/light_record
      method = @objects.respond_to?(:find_each) ? :find_each : :each

      CSV.generate(generator_options) do |csv|
        csv << generate_csv_header unless options[:skip_header] || @fields.nil?

        @objects.send(method) do |object|
          csv << generate_csv_row(object)
        end
      end
    end

    def generate_csv_header
      @fields.collect do |field|
        ::I18n.t('admin.export.csv.header_for_root_methods', name: field.label, model: @abstract_model.pretty_name)
      end +
        @associations.flat_map do |_association_name, option_hash|
          option_hash[:fields].collect do |field|
            ::I18n.t('admin.export.csv.header_for_association_methods', name: field.label, association: option_hash[:association].label)
          end
        end
    end

    def generate_csv_row(object)
      @fields.collect do |field|
        field.with(controller: controller, object: object).export_value
      end +
        @associations.flat_map do |association_name, option_hash|
          associated_objects = [object.send(association_name)].flatten.compact
          option_hash[:fields].collect do |field|
            associated_objects.collect { |ao| field.with(controller: controller, object: ao).export_value.presence || @empty }.join(',')
          end
        end
    end
  end
end
