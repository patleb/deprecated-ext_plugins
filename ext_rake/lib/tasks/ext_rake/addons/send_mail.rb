module ExtRake::Addons
  class SendMail < ExtRake.config.parent_task.constantize
    class Message < ::StandardError
      def backtrace
        ['Notification']
      end
    end

    def self.steps
      [:send_mail]
    end

    def send_mail
      ExtMail::Mailer.new.deliver!(Message.new, subject: self.class.name)
    end
  end
end
