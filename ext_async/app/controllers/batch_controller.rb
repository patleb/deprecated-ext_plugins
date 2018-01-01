class BatchController < ExtAsync.config.parent_controller.constantize
  include ExtAsync::AsLocalRequest

  def exists
    if Batch.exists?
      head :ok
    else
      head :no_content
    end
  end

  def enqueue
    Batch.create! params.permit(:url, :async, :run_at)

    head :created
  end
end
