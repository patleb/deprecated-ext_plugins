# TODO logidze

class AsyncController < ExtAsync.config.parent_controller.constantize
  include ExtAsync::AsLocalRequest

  before_action :to_batch!
  after_action :flash_save!

  protected

  def set_current
    Current.session_id      = params[:_session_id]
    Current.request_id      = params[:_request_id]
    Current.job_id          = params[:_job_id]
    Current.job_timestamp   = params[:_job_timestamp]
    Current.batch_id        = params[:_batch_id]
    Current.batch_timestamp = params[:_batch_timestamp]
    super
  end

  def inline?
    params[:_now].to_b
  end

  private

  def to_batch!
    return if inline?

    processes =
      if (workers = Rails.application.web_workers).any?
        workers.size
      else
        1
      end

    if processes >= ExtAsync.config.min_pool_size
      Batch.create! url: request.original_url, priority: AsyncJob::PRIORITY, run_at: Time.current.utc
      head :accepted
    end
  end

  def flash_save!
    Current.flash.save! if Current.flash
  end
end
