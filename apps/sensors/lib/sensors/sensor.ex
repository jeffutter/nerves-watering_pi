defmodule Sensors.Sensor do
  use Supervisor

  def start_link(address) do
    Supervisor.start_link(__MODULE__, address, [])
  end

  def init(address) do
    children = [
      worker(Sensors.I2CMoistureSensor, [address]),
      worker(Sensors.HistoryManager, [address]),
      worker(Sensors.MetricCollector, [address])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
