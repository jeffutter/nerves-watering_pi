defmodule Sensors.MoistureInstrumenter do
  use Prometheus.Metric

  def setup do
    Gauge.declare([name: :moisture,
                   labels: [:address],
                   help: "Moisture"])
  end

  def set_moisture(label, moisture) do
    Gauge.set([name: :moisture, labels: [label]], moisture)
  end
end
