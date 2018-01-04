module Sh
  module ProcessHelper
    def kill(name, sudo: false)
      %{#{'sudo' if sudo} bash -c 'process_pid=$(pgrep #{name} -o); if [[ ! -z "$process_pid" ]]; then kill $process_pid; fi'}
    end

    def pid(name)
      "pgrep #{name} -o"
    end
  end
end
