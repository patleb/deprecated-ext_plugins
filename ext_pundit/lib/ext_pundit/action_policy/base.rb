module ActionPolicy
  class Base
    include ExtPundit::Actions
    include ExtPundit::Enum

    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        scope
      end
    end
  end
end
