module ActionView
  module WithTemplateVirtualPath
    private

    def determine_template(options)
      template = super
      c = @view.controller
      if c.respond_to? :template_virtual_path
        c.template_virtual_path ||= template.try(:virtual_path)
        @view.instance_variable_set :@h, c.active_helper_class&.new(@view)
      end
      template
    end
  end
end
