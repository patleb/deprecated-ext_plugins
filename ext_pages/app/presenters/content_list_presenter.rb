class ContentListPresenter < ActivePresenter::BaseList
  attr_accessor :multiple, :range

  def initialize(multiple:, range:, **options)
    super
    self.multiple = multiple
    self.range = range
  end
end
