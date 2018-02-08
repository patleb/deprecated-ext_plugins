module ExtRails
  class DbTimeout < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message =~ /PG::QueryCanceled/
    end
  end

  module WithExceptions
    extend ActiveSupport::Concern

    included do
      _process_action_callbacks.each do |callback|
        __send__ "skip_#{callback.kind}_action", callback.filter, only: [:render_404, :render_408, :render_500]
      end

      if ExtRails.config.rescue_500?
        rescue_from StandardError, Exception, with: :render_500
      end
      rescue_from ExtRails::DbTimeout, with: :render_408
    end
  end
end
