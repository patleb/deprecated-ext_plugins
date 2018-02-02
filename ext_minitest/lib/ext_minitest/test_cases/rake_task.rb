module RakeTask
  class TestCase < ActiveSupport::TestCase
    class_attribute :task_namespace

    before(:all) do
      require 'rake'
      Rails.application.all_rake_tasks
    end

    protected

    def run_task(*args)
      Rake::Task[task_name].reenable
      Rake::Task[task_name].invoke(*args)
    end

    def task_name
      if task_namespace.present?
        namespace = "#{task_namespace}:"
      end
      "#{namespace}#{base_name.sub(/Task$/, '').underscore}"
    end
  end
end
