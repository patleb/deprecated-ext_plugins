ActionController::TestCase.class_eval do
  let(:controller){ base_name.constantize.new }

  def method_missing(name, *args, &block)
    controller.__send__(name, *args, &block)
  end

  def respond_to_missing?(name, include_private = false)
    controller.respond_to?(name, include_private) || super
  end

  protected

  def params=(values)
    controller.stubs(:params).returns(values)
  end

  def instance_variable(name)
    controller.send(:instance_variable_get, name)
  end
end
