defmodule Pump do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Pump.Pump, [16, 17, 18])
    ]

    opts = [strategy: :one_for_one, name: Pump.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
