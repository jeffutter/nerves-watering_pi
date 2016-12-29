defmodule Sensors do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Sensors.I2CMultiplexer, [0x70]),
      supervisor(Sensors.Sensor, [{0x70, 0x20, 0}], id: {Sensors.Sensor, 0x70, 0x20, 0}),
      supervisor(Sensors.Sensor, [{0x70, 0x20, 1}], id: {Sensors.Sensor, 0x70, 0x20, 1})
    ]

    opts = [strategy: :one_for_one, name: Sensors.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
