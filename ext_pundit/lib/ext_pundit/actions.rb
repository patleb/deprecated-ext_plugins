module ExtPundit
  module Actions
    extend ActiveSupport::Concern

    included do
      delegate :actions, to: :class
    end

    class_methods do
      def actions
        @_actions ||= begin
          # optimistic/hacky strategy
          checks = public_instance_methods.select{ |m| m.to_s.end_with? '?' }
          blank_index = checks.index :blank? # assuming that blank? index stays a good separator
          checks.each_with_index.select{ |_m, i| i < blank_index }.map(&:first)
        end
      end
    end
  end
end
