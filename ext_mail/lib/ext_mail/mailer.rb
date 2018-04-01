require 'action_view/helpers/text_helper'
require 'settings_yml'

module ExtMail
  class Mailer
    include ActionView::Helpers::TextHelper

    BODY_START = '[NOTIFICATION]'.freeze
    BODY_END = '[END]'.freeze

    # TODO do not raise in test if no deliveries
    def deliver!(exception, subject:, before_body: nil, after_body: nil)
      require "mail"

      mail = ::Mail.new
      mail.delivery_method :smtp, {
        address: SettingsYml[:mail_address],
        port: SettingsYml[:mail_port],
        domain: SettingsYml[:mail_domain],
        user_name: SettingsYml[:mail_user_name],
        password: SettingsYml[:mail_password],
        authentication: "plain",
        enable_starttls_auto: true,
      }
      mail.to   = SettingsYml[:mail_to]
      mail.from = SettingsYml[:mail_from]
      message = <<~TEXT
        #{BODY_START}[#{Time.current.utc}]#{"\n#{before_body}" if before_body}
        #{exception.backtrace_log}#{"\n#{after_body}" if after_body}
        #{BODY_END}
      TEXT
      mail.subject   = subject.to_s
      mail.text_part = ::Mail::Part.new do
        content_type 'text/plain; charset=UTF-8'
        body message.gsub(/\n/, "\r\n")
      end
      context = self
      mail.html_part = ::Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
            </head>
            <body>
              <p>#{context.simple_format(message, {}, sanitize: true)}</p>
            </body>
          </html>
        HTML
      end

      yield message if block_given?
      mail.deliver!
      message
    end
  end
end
