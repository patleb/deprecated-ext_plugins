# TODO extract into module so it can be injected into action_mailer/delivery_job.rb

class AsyncJob < ActiveJob::Base
  def self.log_file
    @_log_file ||= File.expand_path(File.join(Dir.pwd, "log/#{Rails.env}_async.log"))
  end

  def self.perform_batch(url, **context)
    perform_now(url, _type: 'batch', **context)
  end

  def self.perform_now(url,**context)
    super(url, wait: nil, _now: true, **context)
  end

  def perform(url, wait: nil, _now: nil, _type: 'job', **context)
    context.merge!(
      _now: _now,
      _request_id: Current.request_id,
      _session_id: Current.session_id,
      _locale: Current.locale,
      _time_zone: Current.time_zone,
      _currency: Current.currency,
      "_#{_type}_id": job_id,
      "_#{_type}_timestamp": Time.current.utc.iso8601,
    )
    context.compact!
    url = normalize_url(url, context)

    if _now || ExtAsync.config.inline?
      run_inline url
    else
      run_async url, wait
    end
  end

  protected

  def run_inline(url)
    ActionController::Base.dispatch_now(url)
  end

  def run_async(url, wait)
    cmd = Sh.http_get url, username: 'deployer', password: SettingsYml[:deployer_password]
    cmd = "#{cmd} > /dev/null 2> #{self.class.log_file}"
    wait =
      case wait
      when ActiveSupport::Duration
        (wait.to_f / 60).ceil
      else
        wait
      end
    cmd = %{echo "#{cmd}" | at now + #{wait} minutes} if wait

    Thread.new{ Open3.popen3(cmd) }
  end

  private

  def normalize_url(url, params)
    url =
      if url.match /^https?:\/\//
        ActionController::Base.merge_url(url, params)
      elsif url.match /\w+_url$/
        Rails.application.routes.url_helpers.send url, params
      else
        raise ArgumentError, "Invalid url [#{url}]"
      end
    raise ArgumentError, "Must be an async controller [#{url}]" unless url.include? '/_async/'

    url
  end
end
