module Async
  class TaskController < ExtTasks.config.parent_async.constantize
    def perform_now
      task = Task.find(params.require(:id))
      task.update! params.permit(:argurments, :_skip_lock)
      unless inline?
        # TODO I18n messages
        if task.errors.empty?
          # TODO exponential polling with an asymptote if there is a session, otherwise, do not poll
          Flash[:success] = 'Succeeded!'
        else
          Flash[:error] = task.errors.full_messages.join("\n")
        end
      end
    end
  end
end
