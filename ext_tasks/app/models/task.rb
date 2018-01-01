class Task < ExtTasks.config.parent_model.constantize
  RUNNING = '[RUNNING]'

  include ActionView::Helpers::DateHelper

  class List < Array
    def page(*_);       self end
    def per(*_);        self end
    def reorder(*_);    self end
    def references(*_); self end
    def merge(*_);      self end

    def where(query, *params)
      if query.is_a? Hash
        name = query['id'] || query[:id]
        return self.class.new([find{ |task| task.id == name }])
      end
      if params.empty?
        return self
      end

      text = params.last.gsub(/(^%|%$)/, '').downcase

      attributes = query.split('OR').map{ |attr| attr.gsub(/(^ ?\(objects\.| ILIKE \?\) ?$)/, '') }

      self.class.new(select{ |task| attributes.any?{ |attr| task.send(attr).to_s.downcase.include?(text) } })
    end
  end

  attribute :id
  attribute :parameters
  attribute :description
  attribute :output
  attribute :arguments
  attribute :status, :boolean
  attribute :_later, :boolean
  attribute :_skip_lock, :boolean

  validate :save_later

  def self.find(id)
    unless (object = all.where(id: id).first)
      raise ::ActiveRecord::RecordNotFound
    end

    object
  end

  def self.all
    outputs = ::Global.fetch_multi(*ExtTasks.config.tasks_visible.keys.map{ |id| global_key(id) }, expires: true){ '' }
    list = ExtTasks.config.tasks_visible.map do |name, task|
      new(
        id: name, 
        parameters: task.arg_names.join(', '), 
        description: task.comment, 
        output: outputs[global_key(name)],
      )
    end.sort_by(&:id)

    List.new(list)
  end

  def self.global_key(id)
    "ext_tasks:#{id}"
  end

  def persisted?; true end

  def status
    if output.present? && output.exclude?(RUNNING)
      output.include? ActiveTask::Base::TASK_COMPLETED
    end
  end

  private

  def save_later
    if _skip_lock?
      save_now
    elsif acquire_lock
      if _later?
        AsyncJob.perform_later 'async_task_url', id: id, arguments: arguments, _skip_lock: true
      else
        save_now
      end
    else
      errors.add :base, :already_running
    end
  end

  def save_now
    String.try :disable_colorization=, true
    args = arguments.to_s.split(',').map(&:strip)
    ARGV.clear
    result = Rake::Task[id].invoke(*args)
    if result.exclude? ActiveTask::Base::TASK_STARTED
      result = to_completed_task
    end
  rescue => exception
    ExtMail::Mailer.new.deliver!(exception, subject: id) do |message|
      result = to_failed_task(message)
      Rails.logger.error(result)
    end
  ensure
    String.try :disable_colorization=, false
    Rake::Task[id].reenable
    self.output = ::Global.write(global_key, result, expires: true)
  end

  def acquire_lock
    record = ::Global.fetch_record(global_key, expires: true){ '' }
    record.with_lock do
      if record.data&.include? RUNNING
        false
      else
        record.update! data: (self.output = to_running_task)
        true
      end
    end
  end

  def global_key
    self.class.global_key(id)
  end

  def to_running_task
    "#{RUNNING}\n[#{Time.current.utc}][task] #{id}"
  end

  def to_completed_task
    to_active_task(ActiveTask::Base::TASK_COMPLETED)
  end

  def to_failed_task(message)
    to_active_task(ActiveTask::Base::TASK_FAILED, message)
  end

  def to_active_task(state, output = self.output)
    unless output.include? RUNNING
      output = self.output << "\n" << output
    end
    start = Time.parse(output.match(/#{Regexp.quote RUNNING}\n\[(.+)\]\[task\]/)[1])
    result = output.sub RUNNING, ActiveTask::Base::TASK_STARTED
    result << "\n" << "#{state} after #{distance_of_time (Time.current.utc - start).seconds}"
  end
end
