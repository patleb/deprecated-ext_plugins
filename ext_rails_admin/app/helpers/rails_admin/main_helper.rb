module RailsAdmin
  module MainHelper
    def rails_admin_form_for(*args, &block)
      options = args.extract_options!.reverse_merge(builder: RailsAdmin::FormBuilder)
      options[:html] ||= {}
      options[:html][:novalidate] = true unless options[:html].has_key?(:novalidate)
      options[:remote] = true unless options.has_key?(:remote)

      form_for(*(args << options), &block) << after_nested_form_callbacks
    end

    def bs_form_row
      'input-group col-xs-8 col-sm-6 col-md-4 col-lg-4 bs_form_row'
    end

    def get_indicator(percent)
      return '' if percent < 0          # none
      return 'info' if percent < 34     # < 1/100 of max
      return 'success' if percent < 67  # < 1/10 of max
      return 'warning' if percent < 84  # < 1/3 of max
      'danger'                          # > 1/3 of max
    end

    def return_to
      return_to = params[:return_to].presence || request.referer
      return if return_to.try(:match, /\/(delete|sign_in)$/)
      return if action_name.in? %w(chart export)
      return_to
    end

    def to_integer(value)
      value.to_i.to_s.reverse.gsub(/...(?!-)(?=.)/,'\& ').reverse
    end

    def to_hours(value, **options)
      mm, ss = value.divmod(60)
      hh, mm = mm.divmod(60)
      # dd, hh = hh.divmod(24)

      if options[:ceil]
        hh += 1 if (mm != 0 || ss != 0)
        "#{hh}h"
      elsif options[:floor]
        "#{hh}h"
      else
        if hh == 0
          if mm == 0
            "#{ss}s"
          else
            "#{mm}m #{ss}s"
          end
        else
          "#{hh}h #{mm}m #{ss}s"
        end
      end
    end

    def to_local_time(value)
      value.in_time_zone.strftime('%Y-%m-%d %H:%M:%S')
    end

    def to_local_date(value)
      value.in_time_zone.strftime('%Y-%m-%d')
    end

    def after_nested_form(association, &block)
      @nested_form_associations ||= {}
      @nested_form_callbacks ||= []
      unless @nested_form_associations[association]
        @nested_form_associations[association] = true
        @nested_form_callbacks << block
      end
    end

    private

    def after_nested_form_callbacks
      @nested_form_callbacks ||= []
      fields = []
      while (callback = @nested_form_callbacks.shift)
        fields << callback.call
      end
      fields.join.html_safe
    end
  end
end
