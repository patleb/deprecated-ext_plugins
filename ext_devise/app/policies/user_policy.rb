class UserPolicy < ApplicationPolicy
  def export?
    false
  end

  def chart?
    false
  end

  def history?
    false
  end

  def show?
    false
  end

  def show_in_app?
    false
  end

  def report?
    false
  end

  def clone?
    false
  end

  def choose?
    false
  end
end
