class ExtRake::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/ext_rake.rake'
  end

  initializer 'ext_rake.output' do
    require 'rake/task'

    Rake::Task.class_eval do
      module WithOutput
        attr_accessor :output

        def execute(args = nil)
          self.output = ''
          super
          output.dup
        end
      end
      prepend WithOutput
    end
  end
end
