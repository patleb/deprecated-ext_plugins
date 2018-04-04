module ExtRake
  module Pgslice
    extend ActiveSupport::Concern

    included do
      include Psql
    end

    class_methods do
      def adapter
        ActiveRecord::Base
      end
    end
    
    protected

    def pgslice_cmd
      @pgslice_cmd ||= begin
        cmd = "PGSLICE_URL=#{self.class.psql_url} bundle exec pgslice"
        if self.class.respond_to? :gemfile
          cmd = "BUNDLE_GEMFILE=#{self.class.gemfile} #{cmd}"
        end
        cmd
      end
    end
  end
end
