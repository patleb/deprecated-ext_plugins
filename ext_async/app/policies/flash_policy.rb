class FlashPolicy < ApplicationPolicy
  def dashboard?
    false
  end

  def export?
    false
  end

  def chart?
    false
  end

  def history?
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

  def edit?
    false
  end

  def clone?
    false
  end

  def destroy?
    false
  end
end
