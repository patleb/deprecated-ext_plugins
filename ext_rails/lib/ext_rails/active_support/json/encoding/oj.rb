module ActiveSupport::JSON::Encoding
  class Oj < JSONGemEncoder
    def encode(value)
      ::Oj.dump(value)
    end
  end
end

Oj.default_options = {
  float_precision: 16,
  bigdecimal_as_decimal: false,
  nan: :null,
  time_format: :xmlschema,
  second_precision: 3,
  escape_mode: :xss_safe,
  mode: :compat,
  use_as_json: true,
}

ActiveSupport.json_encoder = ActiveSupport::JSON::Encoding::Oj
