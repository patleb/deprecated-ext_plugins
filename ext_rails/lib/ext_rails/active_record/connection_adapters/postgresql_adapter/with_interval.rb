# https://gist.github.com/vollnhals/a7d2ce1c077ae2289056afdf7bba094a

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQLAdapter::WithInterval
      def initialize_type_map(m)
        super(m)
        m.register_type 'interval' do |_, _, sql_type|
          precision = extract_precision(sql_type)
          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Interval.new(precision: precision)
        end
      end

      def configure_connection
        super
        execute('SET intervalstyle = iso_8601', 'SCHEMA')
      end
    end
  end
end
