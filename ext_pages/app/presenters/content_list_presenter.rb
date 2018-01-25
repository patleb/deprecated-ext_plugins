class ContentListPresenter < ActivePresenter::BaseList
  attr_accessor :with_copies, :range

  def initialize(with_copies:, range:, **options)
    super
    self.with_copies = with_copies
    self.range = range
  end
end
