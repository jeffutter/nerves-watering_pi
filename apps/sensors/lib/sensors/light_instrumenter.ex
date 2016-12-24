defmodule Sensors.LightInstrumenter do
  use Prometheus.Metric

  def setup do
    Gauge.declare([name: :light,
                   help: "Light"])
  end

  def set_light(light) do
    Gauge.set([name: :light], light)
  end
end
