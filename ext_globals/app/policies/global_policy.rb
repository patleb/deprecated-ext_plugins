class GlobalPolicy < ApplicationPolicy
  def export?
    false
  end

  def chart?
    false
  end

  def show_in_app?
    false
  end

  def report?
    false
  end

  def new?
    false
  end

  def clone?
    false
  end

  def edit?
    false
  end

  def choose?
    false
  end
end
