module RailsAdmin
  module Main
    class Base < ActiveHelper::Base[:@model_config, :@abstract_model]
      def filter_box
        @_filter_box ||= FilterBox.new(view)
      end

      def choose
        @_choose ||= Choose.new(view)
      end
    end
  end
end
