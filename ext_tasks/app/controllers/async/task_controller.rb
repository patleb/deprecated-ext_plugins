module Async
  class TaskController < ExtTasks.config.parent_async.constantize
    def perform_now
      Task.find(params.require(:id)).update! params.permit(:argurments, :_skip_lock)
    end
  end
end
