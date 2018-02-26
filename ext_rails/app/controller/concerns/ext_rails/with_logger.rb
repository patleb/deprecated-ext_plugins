module ExtRails
  module WithLogger
    def log(exception, subject:, throttle_key: 'ext_rails', throttle_duration: nil)
      return if Current[:log_throttled]

      throttle_value = { type: exception.class.to_s, message: exception.message }
      status = ExtThrottler.status(key: throttle_key, value: throttle_value, duration: throttle_duration)
      return if status[:throttled]

      Current[:log_throttled] = true
      context = request_context.each_with_object('') do |(type, values), memo|
        case values
        when Array
          memo << "\n[#{values.join('][')}]\n"
        when Hash
          memo << "\n[#{type.to_s.upcase}]\n#{values}\n"
        end
      end
      if status[:previous]
        count, previous = status[:count], "\n[#{status[:previous]['type']}]\n[#{status[:previous]['message']}]\n"
      else
        count, previous = 0, ''
      end
      context << "[PREVIOUS_EXCEPTION_COUNT][#{count}]#{previous}"

      message = ExtMail::Mailer.new.deliver!(exception, subject: subject, after_body: context) do |message|
        Rails.logger.error message
      end

      yield message if block_given?
    end

    protected

    def request_context
      {
        origin: %i(remote_ip method original_url content_type).map!{ |attr| request.send(attr) },
        params: request.filtered_parameters.except(*%W(controller action format #{controller_name.singularize})),
        headers: request.headers.env.select{ |header| header =~ /^HTTP_/ },
        session: session.try(:to_hash) || {},
      }
    end
  end
end
