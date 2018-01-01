Logidze::Model.module_eval do
  def whodunnit
    if (id = log_data.responsible_id).present?
      # TODO clear on update/undo/redo
      @_whodunnit ||= OrmAdapter::ActiveRecord.new(User).get(id)
    end
  end
end
