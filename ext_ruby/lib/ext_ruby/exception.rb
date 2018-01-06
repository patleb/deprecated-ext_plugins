Exception.class_eval do
  def backtrace_log(n = 20)
    log = ["[#{self.class}]"]
    log << message if message != self.class.to_s
    log.concat((backtrace || []).first(n)).join("\n").sub('<', '[').sub('>', ']')
  end
end
