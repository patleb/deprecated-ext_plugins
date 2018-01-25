module ActionView
  module WithActivePresenter
    private

    def determine_template(options)
      template = super
      c = @view.controller
      if c.respond_to?(:presenter_lists) && (lists = c.presenter_lists)
        lists = lists.each_with_object({}) do |(name, list_options), memo|
          memo[name.to_sym] = ActivePresenter::BaseList.cast(view: @view, **list_options)
        end

        names = lists.keys
        klass = Class.new do
          attr_reader *names

          def initialize(lists)
            lists.each do |name, list|
              instance_variable_set :"@#{name}", list
            end
          end

          def [](name)
            send(name)
          end
        end

        @view.instance_variable_set :@p, klass.new(lists)
      end
      template
    end
  end
end
