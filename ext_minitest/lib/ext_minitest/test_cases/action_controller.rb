ActionController::TestCase.class_eval do
  let(:controller){ base_name.constantize.new }

  def method_missing(name, *args, &block)
    controller.__send__(name, *args, &block)
  end

  def respond_to_missing?(name, include_private = false)
    controller.respond_to?(name, include_private) || super
  end

  def reset
    @_memoized.delete('controller')
    if @controller
      @controller.send(:instance_variables).each do |name|
        @controller.send(:remove_instance_variable, name)
      end
    end
  end

  protected

  def params=(values)
    controller.stubs(:params).returns(values)
  end

  def [](name)
    controller.send(:instance_variable_get, name)
  end
  
  def []=(name, value)
    controller.send(:instance_variable_set, name, value)
  end
end
