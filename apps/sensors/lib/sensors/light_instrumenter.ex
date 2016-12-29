defmodule Sensors.LightInstrumenter do
  use Prometheus.Metric

  def setup do
    Gauge.declare([name: :light,
                   labels: [:address],
                   help: "Light"])
  end

  def set_light(label, light) do
    Gauge.set([name: :light, labels: [label]], light)
  end
end
