module Async
  class TaskController < ExtTasks.config.parent_async.constantize
    def perform_now
      task = Task.find(name = params.require(:id))
      task.update! params.permit(:argurments, :_skip_lock)
      unless inline?
        if task.errors.empty?
          Flash[:success_sticky] = I18n.t('ext_tasks.flash.success_html', name: name)
        else
          Flash[:error] = I18n.t('ext_tasks.flash.error_html', name: name)
          Flash[:error] += %(<br>- #{task.errors.full_messages.join('<br>- ')})
        end
      end
    end
  end
end
