module Server
  class Global < ActiveType::Record[::Global]
    include AsServerRecord
  end
end if defined? ExtMultiverse
