module ExtRake
  module Raise
    extend ActiveSupport::Concern

    class Failed < ::StandardError; end

    class_methods do
      def ignored_errors
        []
      end

      def sanitized_lines
        {}
      end
    end

    protected

    def notify?(stderr)
      stderr.strip.split("\n").lazy.map(&:strip).any? do |line|
        line.present? && self.class.ignored_errors.none? do |ignored_error|
          if ignored_error.is_a? Regexp
            line.match ignored_error
          else
            line == ignored_error
          end
        end
      end
    end

    def notify!(cmd, stderr)
      cmd = self.class.sanitized_lines.each_with_object(cmd) do |(id, match), memo|
        memo.gsub! match, "[#{id}]"
      end
      stderr = stderr.strip.split("\n").map(&:strip).select do |line|
        line.present? && self.class.ignored_errors.none? do |ignored_error|
          if ignored_error.is_a? Regexp
            line.match ignored_error
          else
            line == ignored_error
          end
        end
      end.join("\n")

      raise Failed, "[#{cmd}]\n\n#{stderr}"
    end
  end
end
