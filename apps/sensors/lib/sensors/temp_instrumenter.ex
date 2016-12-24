defmodule Sensors.TempInstrumenter do
  use Prometheus.Metric

  def setup do
    Gauge.declare([name: :temperature,
                   help: "Temperature"])
  end

  def set_temp(temp) do
    Gauge.set([name: :temperature], temp)
  end
end
