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
  attribute :completed, :boolean
  attribute :updated_at, :datetime
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
    # TODO doesn't work when only 1 entry
    # TODO might make sense to have a dedicated table instead of using Global
    outputs = ::Global.fetch_multi(*ExtTasks.config.tasks_visible.keys.map{ |id| global_key(id) }){ '' }
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

  def completed
    if output.present? && output.exclude?(RUNNING)
      output.include? ExtRake::TASK_COMPLETED
    end
  end

  def updated_at
    if output.present? && output.include?(ExtRake::TASK_DONE)
      Time.zone.parse output.match(/\[(.+)\]#{ExtRake::TASK_DONE.escape_regex}/)[1]
    end
  end

  private

  def save_later
    if _skip_lock?
      save_now
    elsif acquire_lock
      if _later?
        AsyncJob.perform_flash 'async_task_url', id: id, arguments: arguments, _skip_lock: true
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
    # TODO output somewhere/somehow the resources used during the task (cpu, mem, swap, disk)
    result = Rake::Task[id].invoke(*args)
  ensure
    if result.include? ExtRake::TASK_FAILED
      errors.add :base, to_failed_task(result) # TODO still show success
    end
    String.try :disable_colorization=, false
    Rake::Task[id].reenable
    self.output = ::Global.write(global_key, result)
  end

  def acquire_lock
    record = ::Global.fetch_record(global_key){ '' }
    record.with_lock do
      # TODO doesn't work when inline
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
    "#{RUNNING} #{id}\n[#{Time.current.utc}][task]"
  end

  def to_failed_task(result)
    lines = result.split("\n")
    index = lines.index{ |l| l.include? ExtMail::Mailer::BODY_START }
    lines[(index + 1)..(index + 2)].join("\n")
  end
end
