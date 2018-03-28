module ExtRake
  TASK_STARTED = '[STARTED]'.freeze
  TASK_COMPLETED = '[COMPLETED]'.freeze
  TASK_FAILED = '[FAILED]'.freeze
  TASK_DONE = '[done]'.freeze
end

class ExtRake::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/ext_rake.rake'
  end

  initializer 'ext_rake.output' do
    require 'rake/task'

    Rake::Task.class_eval do
      include ActionView::Helpers::DateHelper
      include ActionView::Helpers::NumberHelper

      def self.log_file
        @_log_file ||= File.expand_path(File.join(Dir.pwd, "log/rake.log"))
      end

      module WithOutput
        attr_accessor :output

        def puts(obj = '', *arg)
          self.output ||= ''
          self.output << obj << "\n"
          super
        end

        def execute(args = nil)
          return super if (ARGV.include? '--help') \
            || name == 'environment' \
            || name.start_with?('assets:') \
            || name.start_with?('db:') \
            || name.start_with?('yarn:') \
            || ExtRake.config.skip_override

          time = Time.current.utc
          self.output = ''
          I18n.with_locale(:en) do
            Time.use_zone('UTC') do
              begin
                puts "#{ExtRake::TASK_STARTED} #{name}".blue
                super
              rescue StandardError, Exception => exception
                # TODO mail only if not from TaskController#perform_now
                ExtMail::Mailer.new.deliver! exception, subject: name do |message|
                  puts message
                  Rails.logger.error message
                end
              ensure
                puts "[#{time}][task]" if output.exclude? '[step]'
                now = Time.current.utc
                puts "[#{now}]#{ExtRake::TASK_DONE}"
                total = now - time
                if exception
                  puts "#{ExtRake::TASK_FAILED} after #{distance_of_time total.seconds}".red
                else
                  puts "#{ExtRake::TASK_COMPLETED} after #{distance_of_time total.seconds}".green
                end

                log_line = {
                  remote_addr:            '127.0.0.1 -',
                  remote_user:            '-',
                  time_local:             "[#{time.strftime('%d/%b/%Y:%H:%M:%S +0000')}]",
                  request:                %{"PUT /task/#{name}/edit HTTP/1.1"},
                  status:                 exception ? '500' : '200',
                  body_bytes_sent:        '-',
                  http_referer:           %{"-"},
                  http_user_agent:        %{"-"},
                  upstream_response_time: "%.3f -" % total.ceil(3),
                  scheme:                 "- -",
                  gzip_ratio:             '-',
                }

                `echo '#{log_line.values.join ' '}' >> #{self.class.log_file}`
              end
            end
          end

          output.dup
        end
      end
      prepend WithOutput
    end
  end
end
