options = {
  forward_emails_to: Class.new do
    def self.to_ary
      Class.new do
        def self.flatten
          Class.new do
            def self.uniq
              if Setting.has_key? :mail_interceptors
                Setting[:mail_interceptors]
              else
                Setting[:mail_to]
              end
            end
          end
        end
      end
    end
  end
}

MAIL_INTERCEPTOR = MailInterceptor::Interceptor.new(options)
