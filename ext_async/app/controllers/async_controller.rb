class AsyncController < ExtAsync.config.parent_controller.constantize
  include ExtAsync::AsLocalRequest

  before_action :to_batch!

  protected

  def set_current
    super
    Current.job_id = params[:_job_id]
    Current.job_timestamp = params[:_job_timestamp]
    Current.batch_id = params[:_batch_id]
    Current.batch_timestamp = params[:_batch_timestamp]
  end

  private

  def to_batch!
    return if params[:_now].to_b

    processes =
      if (workers = Rails.application.web_workers).any?
        workers.size
      else
        1
      end

    if processes >= ExtAsync.config.min_pool_size
      Batch.create! url: request.original_url, async: true, run_at: Time.current.utc
      head :accepted
    end
  end
end
