# TODO https://github.com/sfcgeorge/fancy_to_proc
# https://iain.nl/going-crazy-with-to_proc

Symbol.class_eval do
  def with(*args, &block)
    ->(caller, *rest) { caller.send(self, *rest, *args, &block) }
  end
end
