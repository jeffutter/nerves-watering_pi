defmodule Sensors.MoistureInstrumenter do
  use Prometheus.Metric

  def setup do
    Gauge.declare([name: :moisture,
                   help: "Moisture"])
  end

  def set_moisture(moisture) do
    Gauge.set([name: :moisture], moisture)
  end
end
