module ExtAsync
  class Batches < ExtAsync.config.parent_task.constantize
    def self.steps
      [:perform_all]
    end

    def self.log_file
      @_log_file ||= File.expand_path(File.join(Dir.pwd, 'log/batch.log'))
    end

    def perform_all
      loop do
        time = Time.current.utc
        url, status = perform_one
        break unless url

        uri = URI.parse(url)
        query = uri.query.present? ? "?#{uri.query}" : ''
        fragment = uri.fragment.present? ? "##{uri.fragment}" : ''

        # TODO extract into a method and add $pipe $request_time
        log_line = {
          remote_addr:            '127.0.0.1 -',
          remote_user:            '-',
          time_local:             "[#{time.strftime('%d/%b/%Y:%H:%M:%S +0000')}]",
          request:                %{"GET #{[uri.path, query, fragment].join} HTTP/1.1"},
          status:                 status.to_s,
          body_bytes_sent:        '-',
          http_referer:           %{"-"},
          http_user_agent:        %{"-"},
          upstream_response_time: "%.3f -" % (Time.current.utc - time).ceil(3),
          scheme:                 "#{uri.scheme} -",
          gzip_ratio:             '-',
        }

        `echo '#{log_line.values.join ' '}' >> #{self.class.log_file}`
      end
    end

    private

    def perform_one
      url, status = nil, nil
      Rails.application.reloader.wrap do
        return [nil, nil] unless (batch = Batch.dequeue)

        status, _headers, _body, url = AsyncJob.perform_batch(batch.url)
      end
      [url, status]
    end
  end
end
